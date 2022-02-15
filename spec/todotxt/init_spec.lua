local todotxt = require('todotxt-nvim.todotxt')

describe("Todotxt", function()
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
