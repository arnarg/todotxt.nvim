local TodoTxt = require("todotxt-nvim.todotxt")

local function init(class, opts)
  local self = class.super.init(class, opts.file, {
    priority_words = opts.alt_priority,
  })

  self._.subscribers = {}

  return self
end

local TaskStore = setmetatable({
  super = TodoTxt,
}, {
  __call = init,
  __index = TodoTxt,
  __name = "TaskStore",
})

function TaskStore:start()
  self:reload()
  if self._.watcher ~= nil then
    self._.watcher:stop()
  end
  self._.watcher = vim.loop.new_fs_poll()
  self._.watcher:start(
    self._.filename,
    1500,
    vim.schedule_wrap(function()
      self:reload()
    end)
  )
end

function TaskStore:get_task_by_id(id)
  local task = self:get_tasks()[id]
  if task then
    return task
  end
end

function TaskStore:add_task(t)
  self.super.add(self, t)
  -- Notify subscribers for a snappy update
  self:notify()
  -- Save new tasks to file
  self:save()
end

function TaskStore:remove_task(id)
  self.super.remove(self, id)
  -- Notify subscribers for a snappy update
  self:notify()
  -- Save new tasks to file
  self:save()
end

function TaskStore:update_task(id, t)
  self.super.update(self, id, t)
  -- Notify subscribers for a snappy update
  self:notify()
  -- Save new tasks to file
  self:save()
end

function TaskStore:subscribe(subscriber)
  local len = #self._.subscribers
  self._.subscribers[len + 1] = subscriber
end

function TaskStore:reload()
  self:parse()
  self:notify()
end

function TaskStore:notify()
  for i, subscriber in ipairs(self._.subscribers) do
    vim.schedule(function()
      if not subscriber:update_state(self.tasks) then
        table.remove(self._.subscribers, i)
      end
    end)
  end
end

return TaskStore
