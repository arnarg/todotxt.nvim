local Task = require('todotxt-nvim.todotxt.task')

describe("Todot.txt task", function()
	describe("parsing from string", function()
		describe("with empty string", function()
			local task = ""

			it("should not parse task", function()
				local t = Task(task)
				assert.are.same(nil, t)
			end)
		end)

		describe("with only text", function()
			local task = "Call mom"

			it("should parse task correctly", function()
				local t = Task(task)
				assert.are.same(nil, t.priority)
				assert.are.same(false, t:is_completed())
				assert.are.same("Call mom", t:description())
				assert.are.same("Call mom", t:string())
			end)
		end)

		describe("with priority", function()
			local task = "(A) Call mom"

			it("should parse task correctly", function()
				local t = Task(task)
				assert.are.same("A", t.priority)
				assert.are.same(false, t:is_completed())
				assert.are.same("Call mom", t:description())
				assert.are.same("(A) Call mom", t:string())
			end)
		end)

		describe("with done task", function()
			local task = "x Call mom"

			it("should parse task correctly", function()
				local t = Task(task)
				assert.are.same(nil, t.priority)
				assert.are.same(true, t:is_completed())
				assert.are.same("Call mom", t:description())
				assert.are.same("x Call mom", t:string())
			end)
		end)

		describe("with creation date", function()
			local task = "2020-01-01 Call mom"

			it("should parse task correctly", function()
				local t = Task(task)
				local d = os.time({year=2020, month=1, day=1})
				assert.are.same(nil, t.priority)
				assert.are.same(d, t.creation_date)
				assert.are.same(false, t:is_completed())
				assert.are.same("Call mom", t:description())
				assert.are.same("2020-01-01 Call mom", t:string())
			end)

			describe("and priority", function()
				local task = "(A) 2020-01-01 Call mom"

				it("should parse task correctly", function()
					local t = Task(task)
					local d = os.time({year=2020, month=1, day=1})
					assert.are.same("A", t.priority)
					assert.are.same(d, t.creation_date)
					assert.are.same(false, t:is_completed())
					assert.are.same("Call mom", t:description())
					assert.are.same("(A) 2020-01-01 Call mom", t:string())
				end)
			end)

			describe("and done", function()
				local task = "x 2020-01-10 2020-01-01 Call mom"

				it("should parse task correctly", function()
					local t = Task(task)
					local d = os.time({year=2020, month=1, day=1})
					local c = os.time({year=2020, month=1, day=10})
					assert.are.same(true, t:is_completed())
					assert.are.same(d, t.creation_date)
					assert.are.same(c, t.completion_date)
					assert.are.same("Call mom", t:description())
					assert.are.same("x 2020-01-10 2020-01-01 Call mom", t:string())
				end)
			end)
		end)

		describe("with completion date", function()
			local task = "x 2020-01-10 Call mom"

			it("should parse task correctly", function()
				local t = Task(task)
				local d = os.time({year=2020, month=1, day=10})
				assert.are.same(true, t:is_completed())
				assert.are.same(nil, t.creation_date)
				assert.are.same(d, t.completion_date)
				assert.are.same("Call mom", t:description())
			end)
		end)

		describe("with projects", function()
			local task = "Call mom +PersonalLife +Family"

			it("should parse task correctly", function()
				local t = Task(task)
				local p = {"PersonalLife", "Family"}
				assert.are.same(p, t.projects)
				assert.are.same("Call mom", t:description())
				assert.are.same("Call mom +PersonalLife +Family", t:string())
			end)
		end)

		describe("with contexts", function()
			local task = "Call mom @Home @Phone"

			it("should parse task correctly", function()
				local t = Task(task)
				local c = {"Home", "Phone"}
				assert.are.same(c, t.contexts)
				assert.are.same("Call mom", t:description())
				assert.are.same("Call mom @Home @Phone", t:string())
			end)
		end)

		describe("with key/values", function()
			local task = "Call mom due:2022-01-01"

			it("should parse task correctly", function()
				local t = Task(task)
				local kv = {
					due = "2022-01-01",
				}
				assert.are.same(kv, t.kv)
				assert.are.same("Call mom", t:description())
				assert.are.same("Call mom due:2022-01-01", t:string())
			end)
		end)

		describe("with priority word", function()
			local pri_words = {
				A = "now",
				C = "today",
				D = "this week",
			}

			describe("now", function()
				local task = "Call mom now"

				it("should parse task correctly", function()
					local t = Task(task, pri_words)
					assert.are.same("A", t.priority)
					assert.are.same("Call mom", t:description())
					assert.are.same("(A) Call mom", t:string())
				end)
			end)

			describe("today", function()
				local task = "Call mom today"

				it("should parse task correctly", function()
					local t = Task(task, pri_words)
					assert.are.same("C", t.priority)
					assert.are.same("Call mom", t:description())
					assert.are.same("(C) Call mom", t:string())
				end)
			end)

			describe("and creation date", function()
				local task = "2022-01-01 Call mom this week"

				it("should parse task correctly", function()
					local t = Task(task, pri_words)
					assert.are.same("D", t.priority)
					assert.are.same("Call mom", t:description())
					assert.are.same("(D) 2022-01-01 Call mom", t:string())
				end)
			end)

			describe("and priority", function()
				local task = "(A) Call mom this week"

				it("should not use priority word", function()
					local t = Task(task, pri_words)
					assert.are.same("A", t.priority)
					assert.are.same("Call mom this week", t:description())
					assert.are.same("(A) Call mom this week", t:string())
				end)
			end)

			describe("and without passing in pri_words", function()
				local task = "Call mom this week"

				it("should not parse priority word", function()
					local t = Task(task)
					assert.are.same(nil, t.priority)
					assert.are.same("Call mom this week", t:description())
					assert.are.same("Call mom this week", t:string())
				end)
			end)
		end)

		describe("with combinations", function()
			describe("of priority and creation date", function()
				local task = "(A) 2022-01-01 Call mom"

				it("should parse task correctly", function()
					local t = Task(task)
					local d = os.time({year=2022, month=1, day=1})
					assert.are.same("A", t.priority)
					assert.are.same(d, t.creation_date)
					assert.are.same("Call mom", t:description())
					assert.are.same("(A) 2022-01-01 Call mom", t:string())
				end)
			end)

			describe("of projects, contexts, and key/values", function()
				local task = "Call mom +Family @Phone @Home +Life due:2022-01-01"

				it("should parse task correctly", function()
					local t = Task(task)
					local kv = {due = "2022-01-01"}
					local c = {"Phone", "Home"}
					local p = {"Family", "Life"}
					assert.are.same(kv, t.kv)
					assert.are.same(c, t.contexts)
					assert.are.same(p, t.projects)
					assert.are.same("Call mom", t:description())
					assert.are.same("Call mom +Family +Life @Phone @Home due:2022-01-01", t:string())
				end)
			end)
		end)

		describe("with a url", function()
			local task = "Read article https://example.com/article"

			it("should not treat the url as key/value", function()
				local t = Task(task)

				assert.are.same("Read article https://example.com/article", t:description())
				assert.are.same(0, #t.kv)
			end)
		end)
	end)

	describe("completing a task", function()
		local task = "Call mom"

		it("should mark the task as complete", function()
			local t = Task(task)
			assert.are.same(false, t:is_completed())
			t:complete()
			assert.are.same(true, t:is_completed())
			assert.are.same("x Call mom", t:string())
		end)

		describe("with priority", function()
			local task = "(A) Call mom"

			it("should mark the task as complete and move priority to kv", function()
				local t = Task(task)
				assert.are.same(false, t:is_completed())
				t:complete()
				assert.are.same(true, t:is_completed())
				assert.are.same("x Call mom pri:A", t:string())
			end)
		end)
	end)

	describe("uncompleting a task", function()
		local task = "x Call mom"

		it("should mark the task as uncomplete", function()
			local t = Task(task)
			assert.are.same(true, t:is_completed())
			t:uncomplete()
			assert.are.same(false, t:is_completed())
			assert.are.same("Call mom", t:string())
		end)

		describe("with priority", function()
			local task = "x Call mom pri:A"

			it("should mark the task as uncomplete and move priority from kv", function()
				local t = Task(task)
				assert.are.same(true, t:is_completed())
				t:uncomplete()
				assert.are.same(false, t:is_completed())
				assert.are.same("(A) Call mom", t:string())
			end)
		end)
	end)
end)
