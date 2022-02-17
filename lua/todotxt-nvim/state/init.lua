local todotxt = require('todotxt-nvim.todotxt')

local function init(class, options)
	local self = setmetatable({}, { __index = class })

	self._ = {
		file = options.file,
	}

	self._state = {
		tasks = {},
		by_project = {},
		by_context = {},
	}

	return self
end

local TodoStateStore = setmetatable({
	super = nil,
}, {
	__call = init,
	__Name = "TodoStateStore",
})

function TodoStateStore:init()
	self._state.tasks = todotxt.parse_file(self._.file)
	self:_process_projects()
	self:_process_contexts()
end

function TodoStateStore:start_watch(cb)
	if self._.watcher ~= nil then
		self._.watcher:stop()
	end

	self._.watcher = vim.loop.new_fs_poll()
	self._.watcher:start(self._.file, 1500, vim.schedule_wrap(function(handle)
		self._state.tasks = todotxt.parse_file(self._.file)
		self:_process_projects()
		self:_process_contexts()
		vim.schedule(cb)
	end))
end

function TodoStateStore:stop_watch()
	if self._.watcher ~= nil then
		self._.watcher:stop()
	end
end

function TodoStateStore:get_tasks()
	return self._state.tasks
end

function TodoStateStore:get_tasks_by_project(p)
	return self._state.by_project[p]
end

function TodoStateStore:get_tasks_by_context(c)
	return self._state.by_context[c]
end

function TodoStateStore:_process_projects()
	local new_projects = {}

	for _, task in ipairs(self._state.tasks) do
		for _, proj in ipairs(task.projects) do
			if new_projects[proj] == nil then new_projects[proj] = {} end
			local len = #new_projects[proj]
			new_projects[proj][len+1] = task
		end
	end

	self._state.by_project = new_projects
end

function TodoStateStore:_process_contexts()
	local new_contexts = {}

	for _, task in ipairs(self._state.tasks) do
		for _, proj in ipairs(task.contexts) do
			if new_contexts[proj] == nil then new_contexts[proj] = {} end
			local len = #new_contexts[proj]
			new_contexts[proj][len+1] = task
		end
	end

	self._state.by_context = new_contexts
end

return TodoStateStore
