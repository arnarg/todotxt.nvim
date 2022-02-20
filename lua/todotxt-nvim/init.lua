local config = require('todotxt-nvim.config')
local hi_parser = require('todotxt-nvim.parser.highlight')
local TaskStore = require('todotxt-nvim.store.task_store')

local has_nui, Input = pcall(require, 'nui.input')
if not has_nui then
	error "This plugin requires nui.nvim (https://github.com/MunifTanjim/nui.nvim)."
end
local Split = require('todotxt-nvim.ui.split')
local Prompt = require('todotxt-nvim.ui.prompt')
local event = require("nui.utils.autocmd").event

local opts = {}

local store

local todotxt = {}

function todotxt.setup(custom_opts)
	config.set_options(custom_opts)
	opts = require('todotxt-nvim.config').options

	if opts.todo_file == nil then
		error "todo_file path is required."
	end

	opts.todo_file = vim.fn.expand(opts.todo_file)

	store = TaskStore({
		file = opts.todo_file,
	})
	store:start()

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

	vim.cmd("hi todo_txt_done ctermfg=gray guifg=gray")

	vim.cmd("command! ToDoTxtTasks lua require('todotxt-nvim').open_task_pane()")
	vim.cmd("command! ToDoTxtCapture lua require('todotxt-nvim').capture()")
end

function todotxt.open_task_pane()
	if opts == nil then
		error "Setup has not been called."
	end

	local split = Split({
		relative = "editor",
		position = "right",
		size = 35,
		win_options = {
			number = true,
			relativenumber = false,
			cursorline = true,
			cursorlineopt = "number,line",
		},
	})

	split:mount()
	split:set_tasks(store:get_tasks())
	store:subscribe(split)

	-- quit
	split:map("n", "q", function()
	  split:unmount()
	end, { noremap = true })

	-- toggle current node
	split:map("n", "m", function()
		local node = split:get_node()
		
		if node:is_expanded() then
			node:collapse()
		elseif not node:is_expanded() then
			node:expand()
		end
		split:render()
	end, map_options)

	-- delete current node
	split:map("n", "dd", function()
		local node = split:get_node()
		if node ~= nil and node.type == "task" then
			store:del_task_by_id(node.id)
		end
	end)

	-- print current node
	split:map("n", "<CR>", function()
		local node = tree:get_node()
		vim.notify(vim.inspect(node))
	end, map_options)
end

function todotxt.capture()
	if opts == nil then
		error "Setup has not been called."
	end

	local prompt

	function cleanup()
		-- remove reference to the prompt so it can be garbage collected
		prompt = nil
	end

	prompt = Prompt(opts, {
		on_close = cleanup,
		on_submit = function(val)
			store:add_task(val, opts.capture.alternative_priorities)
			cleanup()
		end,
	})

	prompt:mount()

	-- Leaving the buffer is not allowed
	prompt:on(event.BufLeave, function()
		prompt:unmount()
	end)

	prompt:map("n", "<Esc>", prompt.input_props.on_close, { noremap = true })
end

return todotxt
