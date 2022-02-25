local util = require('todotxt-nvim.todotxt.util')

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

local function parse_word_pri(str, pri)
	local p, patt = util.parse_word_pri(str, pri)
	if p ~= nil then
		str = string.gsub(str, "%s*"..patt.."%s*", " ", 1)
	end
	return p, str
end

local function init(class, task_str, pri_words)
	local self = setmetatable({}, { __index = class })

	if not self:parse(task_str, pri_words) then
		return nil
	end

	return self
end

local Task = setmetatable({
	super = nil,
}, {
	__call = init,
	__name = "Task",
})

-- TODO: make sure urls aren't parsed as metadata
function Task:parse(task_str, pri_words)
	local str = trim_space(task_str)
	if #str < 1 then
		return false
	end
	-- Save original string
	self._raw = str

	-- Check if task is done
	self.done, str = parse_done(str)

	-- If the task is marked as done completion date will follow
	if self.done then
		self.completion_date, str = parse_date(str)
	else
		-- If the task is not done then we can check for
		-- a priority
		self.priority, str = parse_pri(str)
	end

	-- Check if creation and completion dates are present
	self.creation_date, str = parse_date(str)

	-- Parse projects
	self.projects, str = parse_specials(str, "%+")

	-- Parse contexts
	self.contexts, str = parse_specials(str, "@")

	-- Parse key/values
	self.kv, str = parse_kv(str)

	-- Look for priority words
	if pri_words ~= nil and self.priority == nil then
		self.priority, str = parse_word_pri(str, pri_words)
	end

	-- Whatever is left of the string is the task
	self.text = trim_space(str)
	return true
end

function Task:is_completed()
	return self.done
end

function Task:description()
	return self.text
end

function Task:string()
	local date_format = "%Y-%m-%d"
	local res = ""
	if self.done then
		res = "x "
		-- According to the spec creation date must be specified if
		-- completion date is
		if self.completion_date ~= nil and self.creation_date ~= nil then
			local cd = os.date(date_format, self.completion_date)
			local crd = os.date(date_format, self.creation_date)
			res = res .. string.format("%s %s ", cd, crd)
		end

		-- If self is done you can add priority as pri:A key value
		if self.priority ~= nil  then
			if self.kv == nil then
				self.kv = {}
			end
			if self.kv["pri"] == nil then
				self.kv["pri"] = self.priority
			end
		end
	else
		if self.priority ~= nil then
			res = "("..self.priority..") "
		end
		if self.creation_date ~= nil then
			res = res .. string.format("%s ", os.date(date_format, self.creation_date))
		end
	end

	res = res .. self.text

	for _, proj in ipairs(self.projects or {}) do
		res = res .. string.format(" +%s", proj)
	end
	for _, cont in ipairs(self.contexts or {}) do
		res = res .. string.format(" @%s", cont)
	end
	for k, v in pairs(self.kv or {}) do
		res = res .. string.format(" %s:%s", k, v)
	end
	return res
end

function Task:complete()
	-- Mark it as complete
	self.done = true
	-- Put priority in metadata
	if self.priority then
		self.kv["pri"] = self.priority
	end
	-- Set completion date
	if self.creation_date then
		self.completion_date = os.time()
	end
end

function Task:uncomplete()
	-- Mark it as not complete
	self.done = false
	-- Fetch priority from metadata
	if self.kv["pri"] ~= nil and string.match(self.kv["pri"], "[A-Z]") then
		self.priority = self.kv["pri"]
		self.kv["pri"] = nil
	end
	-- Unset completion date
	self.completion_date = nil
end

return Task
