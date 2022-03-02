local NuiTree = require("nui.tree")

local Node = {}

function Node.TaskNode(task)
  local fields = {}
  if task.creation_date then
    fields[#fields + 1] = NuiTree.Node({
      type = "meta",
      text = string.format("Creation date: %s", os.date("%Y-%m-%d", task.creation_date)),
    })
  end
  if task.completion_date then
    fields[#fields + 1] = NuiTree.Node({
      type = "meta",
      text = string.format("Completion date: %s", os.date("%Y-%m-%d", task.completion_date)),
    })
  end

  for k, v in pairs(task.kv) do
    fields[#fields + 1] = NuiTree.Node({
      type = "meta",
      text = string.format("%s: %s", k, v),
    })
  end

  local task_node = NuiTree.Node(task, fields)
  task_node.type = "task"
  task_node._task = task

  return task_node
end

return Node
