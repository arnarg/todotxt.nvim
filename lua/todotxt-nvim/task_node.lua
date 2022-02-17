local NuiTree = require('nui.tree')

local TreeTask = {}

function TreeTask.Node(task)
	local fields = {}
	if task.creation_date then
		fields[#fields+1] = NuiTree.Node({ text = string.format("Creation date: %s", os.date("%Y-%m-%d", task.creation_date)) })
	end
	if task.completion_date then
		fields[#fields+1] = NuiTree.Node({ text = string.format("Completion date: %s", os.date("%Y-%m-%d", task.creation_date)) })
	end

	for k, v in pairs(task.kv) do
		fields[#fields+1] = NuiTree.Node({ text = string.format("%s: %s", k, v) })
	end

	task_node = NuiTree.Node(task, fields)
	task_node.type = "task"

	return task_node
end

return TreeTask
