local hi_parser = require('todotxt-nvim.parser.highlight')
local ta_parser = require('todotxt-nvim.parser.todotxt')

local has_nui, Input = pcall(require, 'nui.input')
if not has_nui then
	error "This plugin requires nui.nvim (https://github.com/MunifTanjim/nui.nvim)."
end

local todotxt = {}

function todotxt.setup(custom_opts)

end

function todotxt.add_task(cb)
	local ns = vim.api.nvim_create_namespace("todo_txt")
	local last_start = 0
	local last_stop = 0
	local prompt = "> "

	vim.api.nvim_command("hi todo_txt_pri_a ctermfg=red guifg=red cterm=bold gui=bold")
	vim.api.nvim_command("hi todo_txt_pri_b ctermfg=magenta guifg=magenta cterm=bold gui=bold")
	vim.api.nvim_command("hi todo_txt_pri_c ctermfg=yellow guifg=yellow cterm=bold gui=bold")
	vim.api.nvim_command("hi todo_txt_pri_d ctermfg=cyan guifg=cyan cterm=bold gui=bold")
	vim.api.nvim_command("hi todo_txt_project ctermfg=magenta guifg=magenta")
	vim.api.nvim_command("hi todo_txt_context ctermfg=cyan guifg=cyan")
	vim.api.nvim_command("hi todo_txt_creation_date cterm=underline gui=underline")

	local _popup_options = {
		relative = "editor",
		size = "75%",
		position = "50%",
		border = {
			style = "rounded",
			text = {
				top = "[Add Task]",
				top_align = "center",
			},
		},
		win_options = {
			winhighlight = "Normal:Normal",
		},
	}

	local input = Input(_popup_options, {
		prompt = prompt,
		on_submit = function(val)
			local highlights = hi_parser.parse_task(val)
		end,
		on_change = function(val, b)
			local highlights = hi_parser.parse_task(val)
			local p_length = #prompt
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
				local hi_group = "todo_txt_creation_date"
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
		end,
	})
	input:mount()

	input:map("n", "<Esc>", input.input_props.on_close, { noremap = true })
end

return todotxt
