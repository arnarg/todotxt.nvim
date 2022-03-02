local util = require("todotxt-nvim.parser.util")

describe("Parser utils", function()
  describe("parse_pri", function()
    it("should parse the correct priority with correct bounds", function()
      local task = "(A) Do thing"
      local pri, l, r = util.parse_pri(task)
      assert.are.same("A", pri)
      assert.are.same(1, l)
      assert.are.same(3, r)
    end)

    it("should not parse the priority and find no bounds when no priority is present", function()
      local task = "Do thing"
      local pri, l, r = util.parse_pri(task)
      assert.are.same(nil, pri)
      assert.are.same(1, l)
      assert.are.same(1, r)
    end)
  end)

  describe("parse_date", function()
    it("should parse the correct date with correct bounds", function()
      local task = "2022-01-01 Do thing"
      local date, l, r = util.parse_date(task)
      assert.are.same("2022-01-01", date)
      assert.are.same(1, l)
      assert.are.same(10, r)
    end)

    describe("not at the start of string", function()
      it("should parse date correctly with correct bounds", function()
        local task = "(A) 2022-01-01 Do thing"
        local date, l, r = util.parse_date(task, 5)
        assert.are.same("2022-01-01", date)
        assert.are.same(5, l)
        assert.are.same(14, r)
      end)
    end)
  end)
end)
