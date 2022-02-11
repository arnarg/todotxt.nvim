local parser = require('todotxt-nvim.todotxt.parser')

describe("Task parser", function()
	describe("with only text", function()
		local task = "Call mom"

		it("should parse task with only text", function()
			local t = parser.parse_task(task)
			assert.are.same(nil, t.pri)
			assert.are.same(false, t.done)
			assert.are.same("Call mom", t.text)
		end)
	end)

	describe("with priority", function()
		local task = "(A) Call mom"

		it("should parse task with correct priority", function()
			local t = parser.parse_task(task)
			assert.are.same("A", t.pri)
			assert.are.same(false, t.done)
			assert.are.same("Call mom", t.text)
		end)
	end)

	describe("with done task", function()
		local task = "x Call mom"

		it("should parse task with correct done status", function()
			local t = parser.parse_task(task)
			assert.are.same(nil, t.pri)
			assert.are.same(true, t.done)
			assert.are.same("Call mom", t.text)
		end)
	end)

	describe("with creation date", function()
		local task = "2020-01-01 Call mom"
		it("should parse task correctly with creation date", function()
			local t = parser.parse_task(task)
			local d = os.time({year=2020, month=1, day=1})
			assert.are.same(nil, t.pri)
			assert.are.same(d, t.creation_date)
			assert.are.same("Call mom", t.text)
		end)

		describe("and priority", function()
			local task = "(A) 2020-01-01 Call mom"

			it("should parse task correctly with creation date", function()
				local t = parser.parse_task(task)
				local d = os.time({year=2020, month=1, day=1})
				assert.are.same("A", t.pri)
				assert.are.same(d, t.creation_date)
				assert.are.same("Call mom", t.text)
			end)
		end)

		describe("and done", function()
			local task = "x 2020-01-10 2020-01-01 Call mom"

			it("should parse task correctly with creation and completion date", function()
				local t = parser.parse_task(task)
				local d = os.time({year=2020, month=1, day=1})
				local c = os.time({year=2020, month=1, day=10})
				assert.are.same(true, t.done)
				assert.are.same(d, t.creation_date)
				assert.are.same(c, t.completion_date)
				assert.are.same("Call mom", t.text)
			end)
		end)
	end)

	describe("with completion date", function()
		local task = "x 2020-01-10 Call mom"

		it("should parse task correctly with completion date", function()
			local t = parser.parse_task(task)
			local d = os.time({year=2020, month=1, day=10})
			assert.are.same(true, t.done)
			assert.are.same(nil, t.creation_date)
			assert.are.same(d, t.completion_date)
			assert.are.same("Call mom", t.text)
		end)
	end)

	describe("with projects", function()
		local task = "Call mom +PersonalLife +Family"

		it("should parse task correctly", function()
			local t = parser.parse_task(task)
			local p = {"PersonalLife", "Family"}
			assert.are.same("Call mom", t.text)
			assert.are.same(p, t.projects)
		end)
	end)

	describe("with contexts", function()
		local task = "Call mom @Home @Phone"

		it("should parse task correctly", function()
			local t = parser.parse_task(task)
			local c = {"Home", "Phone"}
			assert.are.same("Call mom", t.text)
			assert.are.same(c, t.contexts)
		end)
	end)

	describe("with key/values", function()
		local task = "Call mom due:2022-01-01 foo:bar"

		it("should parse task correctly", function()
			local t = parser.parse_task(task)
			local kv = {
				due = "2022-01-01",
				foo = "bar",
			}
			assert.are.same("Call mom", t.text)
			assert.are.same(kv, t.kv)
		end)
	end)

	describe("with combinations", function()
		describe("of priority and creation date", function()
			local task = "(A) 2022-01-01 Call mom"

			it("should parse task correctly", function()
				local t = parser.parse_task(task)
				local d = os.time({year=2022, month=1, day=1})
				assert.are.same(d, t.creation_date)
				assert.are.same("Call mom", t.text)
			end)
		end)

		describe("of projects, contexts, and key/values", function()
			local task = "Call mom +Family @Phone @Home +Life due:2022-01-01"

			it("should parse task correctly", function()
				local t = parser.parse_task(task)
				local kv = {due = "2022-01-01"}
				local c = {"Phone", "Home"}
				local p = {"Family", "Life"}
				assert.are.same("Call mom", t.text)
				assert.are.same(kv, t.kv)
				assert.are.same(c, t.contexts)
				assert.are.same(p, t.projects)
			end)
		end)
	end)
end)
