local todotxt = require('todotxt-nvim.todotxt')

describe("Todotxt", function()
	describe("convert task to string", function()
		describe("with basic task", function()
			local task = {
				done = false,
				text = "Do thing",
			}

			it("should convert to string correctly", function()
				local s = todotxt.task_to_string(task)
				assert.are.same("Do thing", s)
			end)
		end)

		describe("with done task", function()
			local d = os.time({year=2022, month=1, day=1})
			local task = {
				done = true,
				completion_date = d,
				creation_date = d,
				text = "Do thing",
			}

			it("should convert to string correctly", function()
				local s = todotxt.task_to_string(task)
				assert.are.same("x 2022-01-01 2022-01-01 Do thing", s)
			end)
		end)

		describe("with prioritized task", function()
			local d = os.time({year=2022, month=1, day=1})
			local task = {
				done = false,
				priority = "A",
				creation_date = d,
				text = "Do thing",
			}

			it("should convert to string correctly", function()
				local s = todotxt.task_to_string(task)
				assert.are.same("(A) 2022-01-01 Do thing", s)
			end)
		end)

		describe("with task that has contexts, projects and kv", function()
			local d = os.time({year=2022, month=1, day=1})
			local task = {
				done = false,
				creation_date = d,
				text = "Do thing",
				contexts = {"phone", "home"},
				projects = {"life", "financials"},
				kv = {
					due = "2022-02-02",
				},
			}

			it("should convert to string correctly", function()
				local s = todotxt.task_to_string(task)
				assert.are.same("2022-01-01 Do thing +life +financials @phone @home due:2022-02-02", s)
			end)
		end)

		describe("with task with mixed fields", function()
			local d = os.time({year=2022, month=1, day=1})
			local task = {
				done = true,
				completion_date = d,
				creation_date = d,
				priority = "B",
				text = "Do thing",
				contexts = {"phone"},
				projects = {"life"},
			}

			it("should convert to string correctly", function()
				local s = todotxt.task_to_string(task)
				assert.are.same("x 2022-01-01 2022-01-01 Do thing +life @phone pri:B", s)
			end)
		end)
	end)

	describe("adding task", function()
		local tfile = io.tmpfile()
		tfile:write("(A) Do thing +Project\n")
		tfile:write("(B) Do another thing @Phone\n")
		tfile:flush()
		local task = "(B) Do third thing"
		local now = os.time()
		local expected = {
			"(A) Do thing +Project",
			"(B) Do another thing @Phone",
			string.format("(B) %s Do third thing", os.date("%Y-%m-%d", now)),
		}

		it("should add new task correctly formatted to end of file", function()
			todotxt.add_task_to_file(task, tfile)
			-- Go to start of file again
			tfile:seek("set")
			local lines = {}
			for line in tfile:lines() do
				lines[#lines+1] = line
			end
			tfile:close()

			assert.are.same(expected, lines)
		end)
	end)

	describe("reading file", function()
		local tfile = io.tmpfile()
		tfile:write("(A) Do thing +Project\n")
		tfile:write("(B) Do another thing @Phone\n")
		tfile:write("Do third thing due:2022-01-01\n")
		tfile:flush()
		tfile:seek("set")
		local expected = {
			{
				id = 1,
				original_string = "(A) Do thing +Project",
				done = false,
				text = "Do thing",
				projects = {"Project"},
				contexts = {},
				kv = {},
				priority = "A",
			},
			{
				id = 2,
				original_string = "(B) Do another thing @Phone",
				done = false,
				text = "Do another thing",
				projects = {},
				contexts = {"Phone"},
				kv = {},
				priority = "B",
			},
			{
				id = 3,
				original_string = "Do third thing due:2022-01-01",
				done = false,
				text = "Do third thing",
				projects = {},
				contexts = {},
				kv = {
					due = "2022-01-01",
				},
			},
		}

		it("should parse tasks correctly", function()
			local tasks = todotxt.parse_file(tfile)
			tfile:close()
			assert.are.same(expected, tasks)
		end)
	end)
end)
