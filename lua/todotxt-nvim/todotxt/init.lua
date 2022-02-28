local Task = require('todotxt-nvim.todotxt.task')

local function init(class, filename, extras)
	local self = setmetatable({}, { __index = class })

	self._ = {
		filename = filename,
		pri_words = (extras or {}).priority_words,
	}

	self.tasks = {}

	return self
end

local TodoTxt = setmetatable({
	super = nil,
}, {
	__call = init,
	__name = "TodoTxt",
})

function TodoTxt:init(filename, extras)
	return init(self, filename, extras)
end

function TodoTxt:parse()
	self.tasks = {}
	for line in io.lines(self._.filename) do
		self:add(line)
	end
	return self.tasks
end

function TodoTxt:build_lines()
	local str = ""

	for _, t in pairs(self.tasks) do
		str = str .. t:string() .. "\n"
	end

	return str
end

function TodoTxt:save()
	local fi = io.open(self._.filename, "w")
	fi:write(self:build_lines())
	fi:close()
end

function TodoTxt:add(task_str)
	local task = Task(task_str, self._.pri_words)
	if task ~= nil then
		if not task.creation_date then
			task.creation_date = os.time()
		end
		-- The next available id becomes the new task's id
		task.id = #self.tasks + 1
		self.tasks[task.id] = task
	end
end

function TodoTxt:remove(id)
	self.tasks[id] = nil
end

function TodoTxt:update(id, task_str)
	local task = Task(task_str, self._.pri_words)
	if task ~= nil then
		task.id = id
		self.tasks[id] = task
	end
end

function TodoTxt:get_tasks()
	return self.tasks
end

function TodoTxt:remove_task(id)
	self.tasks[id] = nil
end

return TodoTxt
