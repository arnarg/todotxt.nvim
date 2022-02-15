local util = require('todotxt-nvim.parser.util')

local parser = {}

local function parse_pri(str, l, r)
	local pri, le, ri = util.parse_pri(str, l)
	if pri ~= nil then
		local _, new_l = string.find(str, "^%s*", ri+1)
		return {
			priority = pri,
			left = le,
			right = ri,
		}, new_l ~= nil and new_l+1 or ri+1
	end
	return nil, le
end

local function parse_date(str, l, r)
	local date, le, ri = util.parse_date(str, l)
	if date ~= nil then
		local _, new_l = string.find(str, "^%s*", ri+1)
		return {
			date = date,
			left = le,
			right = ri,
		}, new_l ~= nil and new_l+1 or ri+1
	end
	return nil, le
end

local function parse_specials(str, sym, l, r)
	local collection = {}
	local le = l
	local ri = r
	while le ~= nil do
		le, ri = string.find(str, sym.."%w+", le)
		if le ~= nil and ri ~= nil then
			collection[#collection+1] = {
				left = le,
				right = ri,
			}
			le = ri + 1
		end
	end
	return #collection > 0 and collection or nil
end

local function parse_tags(str, l, r)
	local tags = {}
	local le = l
	local ri = r
	while le ~= nil do
		le, ri = string.find(str, "[^%s:]+:[^%s:]+", le)
		if le ~= nil and ri ~= nil then
			tags[#tags+1] = {
				left = le,
				right = ri,
			}
			le = ri + 1
		end
	end
	return #tags > 0 and tags or nil
end

local function parse_word_pri(str, pri, l, r)
	local p, _, l, r = util.parse_word_pri(str, pri, l, r)
	return p ~= nil and { priority = p, left = l, right = r } or nil
end

function parser.parse_task(str, pri_words)
	local highlights = {}
	local left = 1

	-- Look for priority in the beginning of string
	highlights.priority, left = parse_pri(str)

	-- Look for creation date next
	highlights.creation_date, left = parse_date(str, left)

	-- Look for projects
	highlights.projects = parse_specials(str, "+", left)

	-- Look for contexts
	highlights.contexts = parse_specials(str, "@", left)

	-- Look for tags
	highlights.tags = parse_tags(str, left)

	-- Look for priority words
	if pri_words ~= nil and highlights.priority == nil then
		highlights.priority_word = parse_word_pri(str, pri_words, left)
	end

	return highlights
end

return parser
