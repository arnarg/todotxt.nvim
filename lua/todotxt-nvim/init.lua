local config = require("todotxt-nvim.config")
local TaskStore = require("todotxt-nvim.store.task_store")
local Split = require("todotxt-nvim.ui.split")
local Prompt = require("todotxt-nvim.ui.prompt")

local opts = {}

local state = {}

local todotxt = {}

local function create_hl_group(n, d)
  local fg = string.format("ctermfg=%s guifg=%s", d.fg or "NONE", d.fg or "NONE")
  local bg = string.format("ctermbg=%s guibg=%s", d.bg or "NONE", d.bg or "NONE")
  local style = string.format("cterm=%s gui=%s", d.style or "NONE", d.style or "NONE")
  vim.cmd(string.format("hi %s %s %s %s", n, fg, bg, style))
  return n
end

local function setup_hl_groups(hls)
  local highlights = {}

  -- Set project, context and date highlights
  for _, hl in ipairs({ "project", "context", "date", "done_task" }) do
    local hl_data = hls[hl]
    if type(hl_data) == "table" then
      highlights[hl] = create_hl_group("todo_txt_" .. hl, hl_data)
    elseif type(hl_data) == "string" then
      highlights[hl] = hl_data
    end
  end

  -- Set priority highlights
  for pri, data in pairs(hls.priorities) do
    local key = "pri_" .. string.lower(pri)
    if type(data) == "table" then
      highlights[key] = create_hl_group("todo_txt_pri_" .. string.lower(pri), data)
    elseif type(data) == "string" then
      highlights[key] = data
    end
  end

  return highlights
end

function todotxt.setup(custom_opts)
  config.set_options(custom_opts)
  opts = require("todotxt-nvim.config").options or {}

  if opts.todo_file == nil then
    error("todo_file path is required.")
  end

  opts.todo_file = vim.fn.expand(opts.todo_file)
  opts.hls = setup_hl_groups(opts.highlights)

  state.store = TaskStore({
    file = opts.todo_file,
    alt_priority = opts.capture.alternative_priority,
  })
  state.store:start()

  vim.cmd("command! ToDoTxtTasksOpen lua require('todotxt-nvim').open_task_pane()")
  vim.cmd("command! ToDoTxtTasksClose lua require('todotxt-nvim').close_task_pane()")
  vim.cmd("command! ToDoTxtTasksToggle lua require('todotxt-nvim').toggle_task_pane()")
  vim.cmd("command! ToDoTxtCapture lua require('todotxt-nvim').capture()")
end

function todotxt.toggle_task_pane()
  if opts == nil then
    error("Setup has not been called.")
  end

  if state.split == nil or (state.split ~= nil and not state.split:is_mounted()) then
    todotxt.open_task_pane()
  else
    todotxt.close_task_pane()
  end
end

function todotxt.open_task_pane()
  if opts == nil then
    error("Setup has not been called.")
  end

  if state.split == nil then
    state.split = Split({
      relative = "editor",
      position = opts.sidebar.position,
      size = opts.sidebar.width,
      hls = opts.hls,
      win_options = {
        number = true,
        relativenumber = false,
        cursorline = true,
        cursorlineopt = "number,line",
      },
    })
  end

  state.split:mount()
  state.split:set_tasks(state.store:get_tasks())
  state.store:subscribe(state.split)

  local map_options = { noremap = true, nowait = true }

  -- quit
  state.split:map("n", opts.keymap.quit, function()
    state.split:unmount()
    state.split = nil
  end, map_options)

  -- toggle current node
  state.split:map("n", opts.keymap.toggle_metadata, function()
    local node = state.split:get_node()
    if node:is_expanded() then
      node:collapse()
    elseif not node:is_expanded() then
      node:expand()
    end
    state.split:render()
  end, map_options)

  -- delete current node
  state.split:map("n", opts.keymap.delete_task, function()
    local node = state.split:get_node()
    if node ~= nil and node.type == "task" then
      state.store:remove_task(node.id)
    end
  end, map_options)

  -- complete task
  state.split:map("n", opts.keymap.complete_task, function()
    local node = state.split:get_node()
    if node ~= nil and node.type == "task" then
      local task = state.store:get_task_by_id(node.id)
      if not task:is_completed() then
        task:complete()
      else
        task:uncomplete()
      end
      state.store:notify()
      state.store:save()
    end
  end, map_options)

  -- edit task
  state.split:map("n", opts.keymap.edit_task, function()
    local node = state.split:get_node()
    if node ~= nil and node.type == "task" then
      todotxt.edit_task(node.id)
    end
  end, map_options)

  -- print current node
  state.split:map("n", "<CR>", function()
    local node = state.split:get_node()
    vim.notify(vim.inspect(node))
  end, map_options)
end

function todotxt.close_task_pane()
  if opts == nil then
    error("Setup has not been called.")
  end

  if state.split ~= nil then
    state.split:unmount()
    state.split = nil
  end
end

function todotxt.edit_task(id)
  if opts == nil then
    error("Setup has not been called.")
  end

  local task = state.store:get_task_by_id(id)

  local _ = Prompt(opts, {
    title = "Edit task",
    initial_value = task:string(),
    on_submit = function(val)
      state.store:update_task(task.id, val)
    end,
  })
end

function todotxt.capture()
  if opts == nil then
    error("Setup has not been called.")
  end

  local _ = Prompt(opts, {
    title = "Add task",
    on_submit = function(val)
      state.store:add_task(val)
    end,
  })
end

return todotxt
