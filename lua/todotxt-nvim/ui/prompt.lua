local NuiInput = require("nui.input")
local hi_parser = require("todotxt-nvim.parser.highlight")
local input = vim.ui.input

local function init(class, opts, extra_opts)
  --[[ local popup_options = vim.tbl_deep_extend("force", opts._popup_options, {
    border = {
      text = {
        top = "[" .. extra_opts.title .. "]",
      },
    },
  }) ]]

  --[[ class.super.init(NuiInput, popup_options, {
    prompt = opts.capture.prompt,
    on_submit = extra_opts.on_submit,
    on_close = extra_opts.on_close,
    default_value = extra_opts.initial_value,
  }) ]]

  local self = class

  self._extra = {
    prompt = opts.capture.prompt,
    alt_pri = opts.capture.alternative_priority,
    mark_id = 0,
    ns = vim.api.nvim_create_namespace("todo_txt"),
    hls = opts.hls,
  }

  -- todo this also needs to be changed
  local function on_change(val)
    local hl_table = {}
    local highlights = hi_parser.parse_task(val, self._extra.alt_pri)
    -- local p_length = #self._extra.prompt
    -- Clear all highlights
    -- vim.api.nvim_buf_clear_namespace(0, self._extra.ns, 0, -1)
    -- Add priority highlight
    if highlights.priority ~= nil then
      local hi_group = self._extra.hls["pri_" .. string.lower(highlights.priority.priority)]
      if hi_group ~= nil then
        --[[ local left = p_length + highlights.priority.left
        local right = p_length + highlights.priority.right ]]
        -- vim.api.nvim_buf_add_highlight(0, self._extra.ns, hi_group, 0, left - 1, right)
        table.insert(hl_table, { highlights.priority.left, highlights.priority.right, hi_group })
      end
    end
    -- Add creation date highlight
    if highlights.creation_date ~= nil then
      local hi_group = self._extra.hls.date
      --[[ local left = p_length + highlights.creation_date.left
      local right = p_length + highlights.creation_date.right ]]
      -- vim.api.nvim_buf_add_highlight(0, self._extra.ns, hi_group, 0, left - 1, right)
      table.insert(hl_table, { highlights.priority.left, highlights.priority.right, hi_group })
    end
    -- Add project highlights
    if highlights.projects ~= nil and #highlights.projects > 0 then
      local hi_group = self._extra.hls.project
      for _, project in ipairs(highlights.projects) do
        --[[ local left = p_length + project.left
        local right = p_length + project.right ]]
        -- vim.api.nvim_buf_add_highlight(0, self._extra.ns, hi_group, 0, left - 1, right)
        table.insert(hl_table, { project.left, project.right, hi_group })
      end
    end
    -- Add context highlights
    if highlights.contexts ~= nil and #highlights.contexts > 0 then
      local hi_group = self._extra.hls.context
      for _, context in ipairs(highlights.contexts) do
        --[[ local left = p_length + context.left
        local right = p_length + context.right
        vim.api.nvim_buf_add_highlight(0, self._extra.ns, hi_group, 0, left - 1, right) ]]
        table.insert(hl_table, { context.left, context.right, hi_group })
      end
    end
    -- Check priority word
    if highlights.priority == nil and highlights.priority_word ~= nil then
      local priority = highlights.priority_word.priority
      local hi_group = self._extra.hls["pri_" .. string.lower(priority)]
      -- Set highlight
      --[[ local left = p_length + highlights.priority_word.left
      local right = p_length + highlights.priority_word.right
      vim.api.nvim_buf_add_highlight(0, self._extra.ns, hi_group, 0, left - 1, right) ]]
      table.insert(hl_table, { highlights.priority_word.left, highlights.priority_word.right, hi_group })
      --[[ -- Set extmark
      local mopts = {
        virt_text = { { priority, hi_group } },
        virt_text_pos = "right_align",
      }
      if self._extra.mark_id ~= 0 then
        mopts.id = self._extra.mark_id
      end
      local _id = vim.api.nvim_buf_set_extmark(0, self._extra.ns, 0, 0, mopts)
      if self._extra.mark_id == 0 then
        self._extra.mark_id = _id
      end
    elseif self._extra.mark_id ~= 0 then
      -- Delete extmark
      vim.api.nvim_buf_del_extmark(0, self._extra.ns, self._extra.mark_id)
      self._extra.mark_id = 0 ]]
    end
    return hl_table
  end

  local input_opts = {
    prompt = opts.capture.prompt,
    default = nil,
    -- this could be later changed to have some useful completions, leaving this be for now
    completion = nil,
    highlight = on_change,
    cancelreturn = nil
  }

  local function on_confirm(input_val)
    if not input_val then
      return
    end
    extra_opts.on_submit(input_val)

  end

  input(input_opts, on_confirm)

  -- This is copied from NuiInput because we need to pass the on_change function as
  -- option to the constructor but we need to have a reference to self which we don't
  -- get until we call the super constructor.
  --[[ self.input_props.on_change = function()
    local value_with_prompt = vim.api.nvim_buf_get_lines(self.bufnr, 0, 1, false)[1]
    local value = string.sub(value_with_prompt, #self._extra.prompt + 1)
    on_change(value, self.bufnr)
  end ]]
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
