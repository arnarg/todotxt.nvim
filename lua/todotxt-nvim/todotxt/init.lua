local Task = require('todotxt-nvim.todotxt.task')

local function init(class, filename, extras)
	local self = setmetatable({}, { __index = class })

	self._ = {
		filename = filename,
		pri_words = extras.priority_words,
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
		-- The next available id becomes the new task's id
		task.id = #self.tasks + 1
		self.tasks[task.id] = task
	end
end

function TodoTxt:get_tasks()
	return self.tasks
end

function TodoTxt:remove_task(id)
	self.tasks[id] = nil
end

return TodoTxt
