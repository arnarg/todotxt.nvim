local priority_table = {
	"A", "B", "C", "D", "E", "F", "G", "H", "I"
}

local util = {}

function util.inc_priority(pri)
	local index
	-- Find current priority index
	for i, p in pairs(priority_table) do
		if p == pri then
			index = i - 1
		end
	end

	-- We went out of bounds, just return back the same priority
	if index < 1 or index > #priority_table then
		return pri
	end

	return priority_table[index]
end

function util.dec_priority(pri)
	local index
	-- Find current priority index
	for i, p in pairs(priority_table) do
		if p == pri then
			index = i + 1
		end
	end

	-- We went out of bounds, just return back the same priority
	if index < 1 or index > #priority_table then
		return pri
	end

	return priority_table[index]
end

return util
