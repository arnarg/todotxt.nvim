local parser = require('todotxt-nvim.parser.todotxt')

local todotxt = {}

local date_format = "%Y-%m-%d"

local function append_to_file(task, f)
	local close = false
	local fi
	if io.type(f) == "file" then
		fi = f
	elseif type(f) == "string" then
		fi = io.open(f, "a")
		close = true
	end
	if fi ~= nil then
		fi:write(string.format("%s\n", task))
	end
	if close and fi ~= nil then fi:close() end
end

function todotxt.task_to_string(task)
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

function todotxt.add_task_to_file(task_str, f, pri_words)
	local task = parser.parse_task(task_str, pri_words)
	if task.text == "" then
		return nil
	end
	-- Task shouldn't be added as complete but we'll at least support it
	if task.done and task.completion_date == nil then
		task.completion_date = os.time()
	end
	-- If task creation date is missing set it to now
	if task.creation_date == nil then
		task.creation_date = os.time()
	end
	out_str = todotxt.task_to_string(task)
	append_to_file(out_str, f)
end

function todotxt.parse_file(f)
	local tasks = {}
	local i = 1
	local fn = function(l)
		task = parser.parse_task(l)
		task.id = i
		tasks[#tasks+1] = task
		i = i+1
	end
	if io.type(f) == "file" then
		for line in f:lines() do fn(line) end
	elseif type(f) == "string" then
		for line in io.lines(f) do fn(line) end
	end
	return tasks
end

return todotxt
