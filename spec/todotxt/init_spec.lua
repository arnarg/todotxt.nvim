local TodoTxt = require("todotxt-nvim.todotxt")

describe("TodoTxt", function()
  describe("with multiple tasks", function()
    local todotxt = TodoTxt(nil, {
      priority_words = {
        A = "now",
        C = "today",
        D = "this week",
      },
    })
    todotxt:add("Do high priority task now")
    todotxt:add("") -- Test an empty line
    todotxt:add("(B) Call mom +PersonalLife @Home")
    todotxt:add("    ") -- Test a line with nothing but whitespace
    todotxt:add("2022-02-25 Do task with date due:2022-02-27")

    it("should parse tasks correctly", function()
      local tasks = todotxt:get_tasks()
      assert.are.same("A", tasks[1].priority)
      assert.are.same("Do high priority task", tasks[1]:description())
      assert.are.same("(A) " .. os.date("%Y-%m-%d", os.time()) .. " Do high priority task", tasks[1]:string())

      assert.are.same("B", tasks[2].priority)
      assert.are.same({ "PersonalLife" }, tasks[2].projects)
      assert.are.same({ "Home" }, tasks[2].contexts)
      assert.are.same("Call mom", tasks[2]:description())
      assert.are.same("(B) " .. os.date("%Y-%m-%d", os.time()) .. " Call mom +PersonalLife @Home", tasks[2]:string())

      assert.are.same({ due = "2022-02-27" }, tasks[3].kv)
      assert.are.same("Do task with date", tasks[3]:description())
      assert.are.same("2022-02-25 Do task with date due:2022-02-27", tasks[3]:string())
    end)

    it("should output correct todotxt string data", function()
      local expected = "(A) "
        .. os.date("%Y-%m-%d", os.time())
        .. " Do high priority task\n"
        .. "(B) "
        .. os.date("%Y-%m-%d", os.time())
        .. " Call mom +PersonalLife @Home\n"
        .. "2022-02-25 Do task with date due:2022-02-27\n"

      assert.are.same(expected, todotxt:build_lines())
    end)
  end)

  describe("updating task", function()
    local todotxt = TodoTxt()
    todotxt:add("(B) Do high priority task")

    it("should change the task accordingly", function()
      local tasks = todotxt:get_tasks()
      assert.are.same("B", tasks[1].priority)
      assert.are.same("Do high priority task", tasks[1]:description())

      todotxt:update(1, "(A) Do very high priority task")
      assert.are.same("A", tasks[1].priority)
      assert.are.same("Do very high priority task", tasks[1]:description())
    end)
  end)

  describe("removing task", function()
    local todotxt = TodoTxt()
    todotxt:add("(B) Do high priority task")

    it("should change the task accordingly", function()
      local tasks = todotxt:get_tasks()
      assert.are.same("B", tasks[1].priority)
      assert.are.same("Do high priority task", tasks[1]:description())

      todotxt:remove(1)
      assert.are.same(nil, tasks[1])
    end)
  end)
end)
