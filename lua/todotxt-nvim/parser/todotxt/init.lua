local util = require('todotxt-nvim.parser.util')

local parser = {}

local function trim_space(str)
	-- Everywhere where there is more than 1 whitespace, replace with one
	str = string.gsub(str, "%s+", " ")
	-- Trim whitespace from beginning and end of string
	return string.match(str, "^%s*(.-)%s*$") or ""
end

local function parse_date_str(d_str)
	local y, m, d = string.match(d_str, "^(%d%d%d%d)%-(%d%d)%-(%d%d)$")
	return os.time({year=y, month=m, day=d})
end

local function parse_done(str)
	local d = string.match(str, "^(x)%s+")
	return d ~= nil, string.gsub(str, "^x%s+", "", 1)
end

local function parse_pri(str)
	local pri, l, r = util.parse_pri(str)
	return pri, pri ~= nil and trim_space(string.sub(str, r+1)) or str
end

local function parse_date(str)
	local md, l, r = util.parse_date(str)
	local date = md ~= nil and parse_date_str(md) or nil
	return date, md ~= nil and trim_space(string.sub(str, r+1)) or str
end

local function parse_specials(str, symbol)
	local collection = {}
	str = string.gsub(str, "%s*"..symbol.."(%w+)%s*", function(m)
		collection[#collection+1] = m
		return " "
	end)
	return collection, str
end

local function parse_kv(str)
	local kv = {}
	-- Both key and value must consist of non-whitespace characters,
	-- which are not colons.
	str = string.gsub(str, "%s*([^%s:]+):([^%s:]+)%s*", function(k, v)
		kv[k] = v
		return " "
	end)
	return kv, str
end


function parser.parse_task(str)
	local task = {}
	-- Save original string
	task.original_string = str

	-- Check if task has priority or is done
	task.done,  str = parse_done(str)

	-- If the task is marked as done completion date will follow
	if task.done then
		task.completion_date, str = parse_date(str)
	else
		-- If the task is not done then we can check for
		-- a priority
		task.pri, str = parse_pri(str)
	end

	-- Check if creation and completion dates are present
	task.creation_date, str = parse_date(str)

	-- Parse projects
	task.projects, str = parse_specials(str, "%+")

	-- Parse contexts
	task.contexts, str = parse_specials(str, "@")

	-- Parse key/values
	task.kv, str = parse_kv(str)

	-- Whatever is left of the string is the task
	task.text = trim_space(str)
	return task
end

return parser
