local TodoTxt = require('todotxt-nvim.todotxt')

describe("TodoTxt", function()
	describe("with multiple tasks", function()
		local todotxt = TodoTxt(nil, {
			priority_words = {
				A = "now",
				C = "today",
				D = "this week",
			}
		})
		todotxt:add("Do high priority task now")
		todotxt:add("(B) Call mom +PersonalLife @Home")
		todotxt:add("2022-02-25 Do task with date due:2022-02-27")

		it("should parse tasks correctly", function()
			local tasks = todotxt:get_tasks()
			assert.are.same("A", tasks[1].priority)
			assert.are.same("Do high priority task", tasks[1]:description())
			assert.are.same("(A) Do high priority task", tasks[1]:string())

			assert.are.same("B", tasks[2].priority)
			assert.are.same({"PersonalLife"}, tasks[2].projects)
			assert.are.same({"Home"}, tasks[2].contexts)
			assert.are.same("Call mom", tasks[2]:description())
			assert.are.same("(B) Call mom +PersonalLife @Home", tasks[2]:string())

			assert.are.same({due = "2022-02-27"}, tasks[3].kv)
			assert.are.same("Do task with date", tasks[3]:description())
			assert.are.same("2022-02-25 Do task with date due:2022-02-27", tasks[3]:string())
		end)

		it("should output correct todotxt string data", function()
			local expected = "(A) Do high priority task\n" ..
					"(B) Call mom +PersonalLife @Home\n" ..
					"2022-02-25 Do task with date due:2022-02-27\n"

			assert.are.same(expected, todotxt:build_lines())
		end)
	end)
end)
