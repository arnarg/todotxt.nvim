local NuiSplit = require('nui.split')
local NuiTree = require('nui.tree')
local NuiLine = require('nui.line')
local event = require('nui.utils.autocmd').event
local Node = require('todotxt-nvim.ui.node')

local function new_node_tree(tasks)
	local nodes = {}

	for id, t in pairs(tasks) do
		table.insert(nodes, Node.TaskNode(t))
	end

	table.sort(nodes, function(t1, t2)
		-- Ascii character '{' comes directly after upper and lowercase
		-- alphabet. Therefor no priority will always come after priorities.
		local pri1 = t1.priority or "{"
		local pri2 = t2.priority or "{"

		-- Ascii character '}' is even later in the ascii table so completed
		-- tasks always come last.
		if t1.done then pri1 = "}" end
		if t2.done then pri2 = "}" end

		if pri1 == pri2 then
			return t1.text < t2.text
		end
		return pri1 < pri2
	end)
	return nodes
end

local function prepare_node(node)
	local line = NuiLine()

	line:append(string.rep("  ", node:get_depth() - 1))

	if node.type == "meta" then
		line:append("  "..node.text, "todo_txt_done")
		return line
	end

	if node.done then
		line:append("x ")
	elseif node.priority then
		local pri_hi = "todo_txt_pri_"..string.lower(node.priority)
		line:append(node.priority, pri_hi)
		line:append(" ")
	else
		line:append("  ")
	end

	line:append(node.text)

	for _, project in ipairs(node.projects) do
		line:append(string.format(" +%s", project), "todo_txt_project")
	end
	for _, context in ipairs(node.contexts) do
		line:append(string.format(" @%s", context), "todo_txt_context")
	end

	if node.done then
		for _, t in ipairs(line._texts) do
			t:set(t:content(), "todo_txt_done")
		end
	end

	return line
end

local function init(class, opts)
	local self = class.super.init(class, opts)

	self._extra = {}

	return self
end

local Split = setmetatable({
	super = NuiSplit,
}, {
	__call = init,
	__index = NuiSplit,
	__name = "Split",
})

function Split:init(opts)
	return init(self, opts)
end

function Split:set_tasks(tasks)
	self._extra.tree = NuiTree({
		winid = self.winid,
		nodes = new_node_tree(tasks),
		prepare_node = prepare_node,
	})
	self._extra.tree:render()
end

function Split:render()
	self._extra.tree:render()
end

function Split:mount()
	self.super.mount(self)
	self._extra.mounted = true
	-- I want to know when window is closed without us being involved
	self:on(event.WinClosed, function()
		self:unmount()
	end)
end

function Split:unmount()
	-- We're no longer interested in this event
	self:off(event.WinClosed)
	self.super.unmount(self)
	self._extra.tree = nil
	self._extra.mounted = false
end

function Split:is_mounted()
	return self._extra.mounted
end

function Split:get_node()
	if self._extra.tree then
		return self._extra.tree:get_node()
	end
end

function Split:update_state(state)
	if self:is_mounted() then
		self:set_tasks(state.tasks)
		return true
	end
	return false
end

return Split
