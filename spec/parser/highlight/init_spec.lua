local parser = require('todotxt-nvim.parser.highlight')

describe("Highlight parser", function()
	describe("with priority", function()
		local task = "(A) Do thing"

		it("should parse correct highlights and priority", function()
			local h = parser.parse_task(task)
			local expected = {
				priority = {
					priority = "A",
					left = 1,
					right = 3,
				},
			}
			assert.are.same(expected, h)
		end)
	end)

	describe("with creation date", function()
		local task = "2022-01-01 Do thing"

		it("should parse correct highlights and date", function()
			local h = parser.parse_task(task)
			local expected = {
				creation_date = {
					date = "2022-01-01",
					left = 1,
					right = 10,
				},
			}
			assert.are.same(expected, h)
		end)

		describe("and priority", function()
			local task = "(A) 2022-01-01 Do thing"

			it("should parse correct highlights and data", function()
				local h = parser.parse_task(task)
				local expected = {
					priority = {
						priority = "A",
						left = 1,
						right = 3,
					},
					creation_date = {
						date = "2022-01-01",
						left = 5,
						right = 14,
					},
				}
				assert.are.same(expected, h)
			end)
		end)
	end)

	describe("with projects", function()
		local task = "Do thing +life +school"

		it("should parse correct highlights and data", function()
			local h = parser.parse_task(task)
			local expected = {
				projects = {
					{left=10, right=14},
					{left=16, right=22},
				},
			}
			assert.are.same(expected, h)
		end)
	end)

	describe("with contexts", function()
		local task = "Do thing @home @phone"

		it("should parse correct highlights and data", function()
			local h = parser.parse_task(task)
			local expected = {
				contexts = {
					{left=10, right=14},
					{left=16, right=21},
				},
			}
			assert.are.same(expected, h)
		end)
	end)

	describe("with contexts", function()
		local task = "Do thing due:2022-01-01 rec:1d"

		it("should parse correct highlights and data", function()
			local h = parser.parse_task(task)
			local expected = {
				tags = {
					{left=10, right=23},
					{left=25, right=30},
				},
			}
			assert.are.same(expected, h)
		end)
	end)

	describe("with priority word", function()
		local pri_words = {
			A = "now",
			B = "today",
			C = "tomorrow",
		}

		describe("today", function()
			local task = "Do thing today"

			it("should parse correct highlight with correct priority", function()
				local h = parser.parse_task(task, pri_words)
				local expected = {
					priority_words = {
						priority = "B",
						left = 10,
						right = 14,
					},
				}
				assert.are.same(expected, h)
			end)
		end)

		describe("tomorrow", function()
			local task = "Do thing tomorrow"

			it("should parse correct highlight with correct priority", function()
				local h = parser.parse_task(task, pri_words)
				local expected = {
					priority_words = {
						priority = "C",
						left = 10,
						right = 17,
					},
				}
				assert.are.same(expected, h)
			end)
		end)
	end)
end)
