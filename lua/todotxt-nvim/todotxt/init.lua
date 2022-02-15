local parser = require('todotxt-nvim.parser.todotxt')

local todotxt = {}

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
