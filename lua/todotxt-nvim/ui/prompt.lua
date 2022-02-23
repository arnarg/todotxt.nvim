local NuiInput = require('nui.input')
local hi_parser = require('todotxt-nvim.parser.highlight')

local function init(class, opts, extra_opts)
	local popup_options = vim.tbl_deep_extend("force", opts._popup_options, {
		border = {
			text = {
				top = "["..extra_opts.title.."]",
			},
		},
	})

	local self = class.super.init(NuiInput, popup_options, {
		prompt = opts.capture.prompt,
		on_submit = extra_opts.on_submit,
		on_close = extra_opts.on_close,
		default_value = extra_opts.initial_value,
	})

	self._extra = {
		prompt = opts.capture.prompt,
		alt_pri = opts.capture.alternative_priority,
		mark_id = 0,
		ns = vim.api.nvim_create_namespace("todo_txt"),
	}

	function on_change(val, b)
		local highlights = hi_parser.parse_task(val, self._extra.alt_pri)
		local p_length = #self._extra.prompt
		-- Clear all highlights
		vim.api.nvim_buf_clear_namespace(b, self._extra.ns, 0, -1)
		-- Add priority highlight
		if highlights.priority ~= nil then
			local hi_group = "todo_txt_pri_"..string.lower(highlights.priority.priority)
			local left = p_length + highlights.priority.left
			local right = p_length + highlights.priority.right
			vim.api.nvim_buf_add_highlight(b, self._extra.ns, hi_group, 0, left-1, right)
		end
		-- Add creation date highlight
		if highlights.creation_date ~= nil then
			local hi_group = "todo_txt_date"
			local left = p_length + highlights.creation_date.left
			local right = p_length + highlights.creation_date.right
			vim.api.nvim_buf_add_highlight(b, self._extra.ns, hi_group, 0, left-1, right)
		end
		-- Add project highlights
		if highlights.projects ~= nil and #highlights.projects > 0 then
			local hi_group = "todo_txt_project"
			for _, project in ipairs(highlights.projects) do
				local left = p_length + project.left
				local right = p_length + project.right
				vim.api.nvim_buf_add_highlight(b, self._extra.ns, hi_group, 0, left-1, right)
			end
		end
		-- Add context highlights
		if highlights.contexts ~= nil and #highlights.contexts > 0 then
			local hi_group = "todo_txt_context"
			for _, context in ipairs(highlights.contexts) do
				local left = p_length + context.left
				local right = p_length + context.right
				vim.api.nvim_buf_add_highlight(b, self._extra.ns, hi_group, 0, left-1, right)
			end
		end
		-- Check priority word
		if highlights.priority == nil and highlights.priority_word ~= nil then
			local priority = highlights.priority_word.priority
			local hi_group = "todo_txt_pri_"..string.lower(priority)
			-- Set highlight
			local left = p_length + highlights.priority_word.left
			local right = p_length + highlights.priority_word.right
			vim.api.nvim_buf_add_highlight(b, self._extra.ns, hi_group, 0, left-1, right)
			-- Set extmark
			local mopts = {
				virt_text = {{priority, hi_group}},
				virt_text_pos = "right_align",
			}
			if self._extra.mark_id ~= 0 then
				mopts.id = self._extra.mark_id
			end
			_id = vim.api.nvim_buf_set_extmark(b, self._extra.ns, 0, 0, mopts)
			if self._extra.mark_id == 0 then
				self._extra.mark_id = _id
			end
		elseif mark_id ~= 0 then
			-- Delete extmark
			vim.api.nvim_buf_del_extmark(b, self._extra.ns, self._extra.mark_id)
			self._extra.mark_id = 0
		end
	end

	-- This is copied from NuiInput because we need to pass the on_change function as
	-- option to the constructor but we need to have a reference to self which we don't
	-- get until we call the super constructor.
	self.input_props.on_change = function()
		local value_with_prompt = vim.api.nvim_buf_get_lines(self.bufnr, 0, 1, false)[1]
      		local value = string.sub(value_with_prompt, #self._extra.prompt + 1)
      		on_change(value)
	end
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
