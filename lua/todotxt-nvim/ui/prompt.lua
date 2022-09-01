local NuiInput = require("nui.input")
local hi_parser = require("todotxt-nvim.parser.highlight")
local input = vim.ui.input

local function init(class, opts, extra_opts)
  local self = class

  self._extra = {
    prompt = opts.capture.prompt,
    alt_pri = opts.capture.alternative_priority,
    mark_id = 0,
    ns = vim.api.nvim_create_namespace("todo_txt"),
    hls = opts.hls,
  }

  local function on_change(val)
    local hl_table = {}
    local highlights = hi_parser.parse_task(val, self._extra.alt_pri)
    -- Add priority highlight
    if highlights.priority ~= nil then
      local hi_group = self._extra.hls["pri_" .. string.lower(highlights.priority.priority)]
      if hi_group ~= nil then
        table.insert(hl_table, { highlights.priority.left - 1, highlights.priority.right, hi_group })
      end
    end
    -- Add creation date highlight
    if highlights.creation_date ~= nil then
      local hi_group = self._extra.hls.date
      table.insert(hl_table, { highlights.priority.left - 1, highlights.priority.right, hi_group })
    end
    -- Add project highlights
    if highlights.projects ~= nil and #highlights.projects > 0 then
      local hi_group = self._extra.hls.project
      for _, project in ipairs(highlights.projects) do
        table.insert(hl_table, { project.left - 1, project.right, hi_group })
      end
    end
    -- Add context highlights
    if highlights.contexts ~= nil and #highlights.contexts > 0 then
      local hi_group = self._extra.hls.context
      for _, context in ipairs(highlights.contexts) do
        table.insert(hl_table, { context.left - 1, context.right, hi_group })
      end
    end
    -- Check priority word
    if highlights.priority == nil and highlights.priority_word ~= nil then
      local priority = highlights.priority_word.priority
      local hi_group = self._extra.hls["pri_" .. string.lower(priority)]
      -- Set highlight
      table.insert(hl_table, { highlights.priority_word.left - 1, highlights.priority_word.right, hi_group })
    end
    return hl_table
  end

  -- This are options which are passed to `vim.ui.input`
  local input_opts = {
    -- specify the input prompt
    prompt = opts.capture.prompt,
    -- there should be no default value
    default = nil,
    -- this could be later changed to have some useful completions, leaving this be for now
    completion = nil,
    -- function which returns a table of highlights
    highlight = on_change,
    -- this is the return value when closing the window(C-c)
    cancelreturn = nil
  }

  -- if the window closes, nil will be passed here and we shouldn't do anything
  -- this is also passed to vim.ui.input
  local function on_confirm(input_val)
    if not input_val then
      return
    end
    extra_opts.on_submit(input_val)

  end

  input(input_opts, on_confirm)

  return self
end

local Prompt = setmetatable({
  super = NuiInput,
}, {
  __call = init,
  __index = NuiInput,
  __name = "Prompt",
})

return Prompt
