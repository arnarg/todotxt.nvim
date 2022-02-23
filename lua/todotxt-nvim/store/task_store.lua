local parser = require('todotxt-nvim.parser.todotxt')
local util = require('todotxt-nvim.store.util')

local function init(class, opts)
	local self = setmetatable({}, { __index = class })

	self._ = {
		file = opts.file,
		alt_priority = opts.alt_priority,
		subscribers = {},
		state = {
			tasks = {},
			by_project = {},
			by_context = {},
		},
	}

	return self
end

local function add_to_projects(task, state)
	for _, p in ipairs(task.projects) do
		if state.by_project[p] == nil then state.by_project[p] = {} end
		local len = #state.by_project[p]
		state.by_project[p][task.id] = task
	end
end

local function add_to_contexts(task, state)
	for _, p in ipairs(task.contexts) do
		if state.by_context[p] == nil then state.by_context[p] = {} end
		state.by_context[p][task.id] = task
	end
end

local function load_state_from_file(file)
	local state = { tasks = {}, by_project = {}, by_context = {} }

	for line in io.lines(file) do
		local task = parser.parse_task(line)
		-- The line number the task was on becomes its id
		task.id = #state.tasks + 1
		state.tasks[task.id] = task
		add_to_projects(task, state)
		add_to_contexts(task, state)
	end

	return state
end

local function to_string(task)
	local date_format = "%Y-%m-%d"
	local res = ""
	if task.done then
		res = "x "
		-- According to the spec creation date must be specified if
		-- completion date is
		if task.completion_date ~= nil and task.creation_date ~= nil then
			local cd = os.date(date_format, task.completion_date)
			local crd = os.date(date_format, task.creation_date)
			res = res .. string.format("%s %s ", cd, crd)
		end

		-- If task is done you can add priority as pri:A key value
		if task.priority ~= nil  then
			if task.kv == nil then
				task.kv = {}
			end
			if task.kv["pri"] == nil then
				task.kv["pri"] = task.priority
			end
		end
	else
		if task.priority ~= nil then
			res = "("..task.priority..") "
		end
		if task.creation_date ~= nil then
			res = res .. string.format("%s ", os.date(date_format, task.creation_date))
		end
	end

	res = res .. task.text

	for _, proj in ipairs(task.projects or {}) do
		res = res .. string.format(" +%s", proj)
	end
	for _, cont in ipairs(task.contexts or {}) do
		res = res .. string.format(" @%s", cont)
	end
	for k, v in pairs(task.kv or {}) do
		res = res .. string.format(" %s:%s", k, v)
	end
	return res
end

function commit_tasks_to_file(tasks, f)
	local str = ""

	for i, t in pairs(tasks) do
		str = str .. string.format("%s\n", to_string(t))
	end

	local fi = io.open(f, "w")
	fi:write(str)
	fi:close()
end

local function append_to_file(task, f)
	local fi = io.open(f, "a")
	fi:write(string.format("%s\n", to_string(task)))
	fi:close()
end

local TaskStore = setmetatable({
	super = nil,
}, {
	__call = init,
	__name = "TaskStore",
})

function TaskStore:start()
	self:reload()
	if self._.watcher ~= nil then
		self._.watcher:stop()
	end
	self._.watcher = vim.loop.new_fs_poll()
	self._.watcher:start(self._.file, 1500, vim.schedule_wrap(function()
		self:reload()
	end))
end

function TaskStore:get_tasks()
	return self._.state.tasks
end

function TaskStore:get_task_by_id(id)
	local task = self._.state.tasks[id]
	if task then
		return self._.state.tasks[id], to_string(self._.state.tasks[id])
	end
end

function TaskStore:add_task(t)
	-- Parse task string
	local task = parser.parse_task(t, self._.alt_priority)
	task.creation_date = os.time()
	-- New task doesn't have an id yet, let's get the next available
	local id = #self._.state.tasks + 1
	task.id = id
	self._.state.tasks[id] = task
	add_to_projects(task, self._.state)
	add_to_contexts(task, self._.state)
	-- Notify subscribers for a snappy update
	self:_notify_subscribers()
	-- Write new task at the end of file
	append_to_file(task, self._.file)
end

function TaskStore:inc_pri_by_task_id(id)
	local task = self._.state.tasks[id]
	task.priority = util.inc_priority(task.priority)
	-- Notify subscribers for a snappy update
	self:_notify_subscribers()
	-- Commit new state to file
	commit_tasks_to_file(self._.state.tasks, self._.file)
end

function TaskStore:dec_pri_by_task_id(id)
	local task = self._.state.tasks[id]
	task.priority = util.dec_priority(task.priority)
	-- Notify subscribers for a snappy update
	self:_notify_subscribers()
	-- Commit new state to file
	commit_tasks_to_file(self._.state.tasks, self._.file)
end

function TaskStore:del_task_by_id(id)
	-- Update local state
	self._.state.tasks[id] = nil
	self._.state.by_project[id] = nil
	self._.state.by_context[id] = nil
	-- Notify subscribers for a snappy update
	self:_notify_subscribers()
	-- Commit new state to file
	commit_tasks_to_file(self._.state.tasks, self._.file)
end

function TaskStore:complete_task_by_id(id)
	local task = self._.state.tasks[id]
	-- Mark it as completed
	task.done = true
	-- Put priority in metadata
	if task.priority then
		task.kv["pri"] = task.priority
	end
	-- Set completion date
	if task.creation_date then
		task.completion_date = os.time()
	end
	-- Notify subscribers for a snappy update
	self:_notify_subscribers()
	-- Commit new state to file
	commit_tasks_to_file(self._.state.tasks, self._.file)
end

function TaskStore:uncomplete_task_by_id(id)
	local task = self._.state.tasks[id]
	-- Mark it as completed
	task.done = false
	-- Put priority in metadata
	if task.kv["pri"] ~= nil and string.match(task.kv["pri"], "[A-Z]") then
		task.priority = task.kv["pri"]
		task.kv["pri"] = nil
	end
	-- Set completion date
	task.completion_date = nil
	-- Notify subscribers for a snappy update
	self:_notify_subscribers()
	-- Commit new state to file
	commit_tasks_to_file(self._.state.tasks, self._.file)
end

function TaskStore:update_task(id, t)
	-- Parse task string
	local task = parser.parse_task(t, self._.alt_priority)
	-- Set the old id on the newly parsed task
	task.id = id
	self._.state.tasks[id] = task
	add_to_projects(task, self._.state)
	add_to_contexts(task, self._.state)
	-- Notify subscribers for a snappy update
	self:_notify_subscribers()
	-- Commit new state to file
	commit_tasks_to_file(self._.state.tasks, self._.file)
end

function TaskStore:subscribe(subscriber)
	local len = #self._.subscribers
	self._.subscribers[len+1] = subscriber
end

function TaskStore:reload()
	self._.state = load_state_from_file(self._.file)
	self:_notify_subscribers()
end

function TaskStore:_notify_subscribers()
	for i, subscriber in ipairs(self._.subscribers) do
		vim.schedule(function()
			if not subscriber:update_state(self._.state) then
				table.remove(self._.subscribers, i)
			end
		end)
	end
end

return TaskStore
