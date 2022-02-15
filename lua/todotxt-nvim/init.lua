local config = require('todotxt-nvim.config')
local hi_parser = require('todotxt-nvim.parser.highlight')
local todo_lib = require('todotxt-nvim.todotxt')

local has_nui, Input = pcall(require, 'nui.input')
if not has_nui then
	error "This plugin requires nui.nvim (https://github.com/MunifTanjim/nui.nvim)."
end

local opts = {}

local todotxt = {}

function todotxt.setup(custom_opts)
	config.set_options(custom_opts)
	opts = require('todotxt-nvim.config').options

	if opts.todo_file == nil then
		error "todo_file path is required."
	end

	-- Set project, context and date highlights
	for _, hl in ipairs({"project", "context", "date"}) do
		local hl_group = "todo_txt_"..hl
		local hl_data = opts.highlights[hl]
		local fg = string.format("ctermfg=%s guifg=%s", hl_data.fg or "NONE", hl_data.fg or "NONE")
		local bg = string.format("ctermbg=%s guibg=%s", hl_data.bg or "NONE", hl_data.bg or "NONE")
		local style = string.format("cterm=%s gui=%s", hl_data.style or "NONE", hl_data.style or "NONE")
		vim.cmd(string.format("hi %s %s %s %s", hl_group, fg, bg, style))
	end

	-- Set priority highlights
	for pri, data in pairs(opts.highlights.priorities) do
		local hl_group = "todo_txt_pri_"..string.lower(pri)
		local fg = string.format("ctermfg=%s guifg=%s", data.fg or "NONE", data.fg or "NONE")
		local bg = string.format("ctermbg=%s guibg=%s", data.bg or "NONE", data.bg or "NONE")
		local style = string.format("cterm=%s gui=%s", data.style or "NONE", data.style or "NONE")
		vim.cmd(string.format("hi %s %s %s %s", hl_group, fg, bg, style))
	end

	vim.cmd("command! ToDoTxtCapture lua require('todotxt-nvim').capture()")
end

function todotxt.capture()
	if opts == nil then
		error "Setup has not been called."
	end

	local ns = vim.api.nvim_create_namespace("todo_txt")
	local mark_id = 0
	local alt_pri = opts.capture.alternative_priority
	local todo_file = opts.todo_file

	local input = Input(opts._popup_options, {
		prompt = opts.capture.prompt,
		on_submit = function(val)
			todo_lib.add_task_to_file(val, todo_file, alt_pri)
		end,
		on_change = function(val, b)
			local highlights = hi_parser.parse_task(val, alt_pri)
			local p_length = #opts.capture.prompt
			-- Clear all highlights
			vim.api.nvim_buf_clear_namespace(b, ns, 0, -1)
			-- Add priority highlight
			if highlights.priority ~= nil then
				local hi_group = "todo_txt_pri_"..string.lower(highlights.priority.priority)
				local left = p_length + highlights.priority.left
				local right = p_length + highlights.priority.right
				vim.api.nvim_buf_add_highlight(b, ns, hi_group, 0, left-1, right)
			end
			-- Add creation date highlight
			if highlights.creation_date ~= nil then
				local hi_group = "todo_txt_date"
				local left = p_length + highlights.creation_date.left
				local right = p_length + highlights.creation_date.right
				vim.api.nvim_buf_add_highlight(b, ns, hi_group, 0, left-1, right)
			end
			-- Add project highlights
			if highlights.projects ~= nil and #highlights.projects > 0 then
				local hi_group = "todo_txt_project"
				for _, project in ipairs(highlights.projects) do
					local left = p_length + project.left
					local right = p_length + project.right
					vim.api.nvim_buf_add_highlight(b, ns, hi_group, 0, left-1, right)
				end
			end
			-- Add context highlights
			if highlights.contexts ~= nil and #highlights.contexts > 0 then
				local hi_group = "todo_txt_context"
				for _, context in ipairs(highlights.contexts) do
					local left = p_length + context.left
					local right = p_length + context.right
					vim.api.nvim_buf_add_highlight(b, ns, hi_group, 0, left-1, right)
				end
			end
			-- Check priority word
			if highlights.priority == nil and highlights.priority_word ~= nil then
				local priority = highlights.priority_word.priority
				local hi_group = "todo_txt_pri_"..string.lower(priority)
				-- Set highlight
				local left = p_length + highlights.priority_word.left
				local right = p_length + highlights.priority_word.right
				vim.api.nvim_buf_add_highlight(b, ns, hi_group, 0, left-1, right)
				-- Set extmark
				mopts = {
					virt_text = {{priority, hi_group}},
					virt_text_pos = "right_align",
				}
				if mark_id ~= 0 then
					mopts.id = mark_id
				end
				_id = vim.api.nvim_buf_set_extmark(b, ns, 0, 0, mopts)
				if mark_id == 0 then
					mark_id = _id
				end
			elseif mark_id ~= 0 then
				-- Delete extmark
				vim.api.nvim_buf_del_extmark(b, ns, mark_id)
				mark_id = 0
			end
		end,
	})
	input:mount()

	input:map("n", "<Esc>", input.input_props.on_close, { noremap = true })
end

return todotxt
