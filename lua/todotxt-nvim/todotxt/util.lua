local util = {}

local date_format = "%d%d%d%d%-%d%d%-%d%d"

-- Looks for a priority in the beginning of the string.
-- Returns the priority if found and the start and stop
-- index where it was found.
function util.parse_pri(str, l, r)
  l = l or 1
  r = r or 1
  local pri = string.match(str, "^%(([A-Z])%)%s+", l)
  local left, right = string.find(str, "^%([A-Z]%)", l)
  return pri, left or l, right or r
end

-- Parses the date
function util.parse_date(str, l, r)
  l = l or 1
  r = r or 1
  local date = string.match(str, "^(" .. date_format .. ")%s+", l)
  local left, right = string.find(str, "^" .. date_format, l)
  return date, left or l, right or r
end

function util.parse_word_pri(str, pri, l, r)
  if type(pri) == "table" then
    for p, patt in pairs(pri) do
      local le, ri = string.find(str, patt, l)
      if le ~= nil and util.isolated(str, patt, l, r) then
        return p, patt, le, ri
      end
    end
  end
end

-- Checks that a word is either around either end of string
-- or wrapped in whitespace
function util.isolated(str, w, l, r)
  local match = string.match
  if l ~= nil then
    str = string.sub(str, l, r)
  end
  local prefix = match(str, "^" .. w) or match(str, "%s" .. w)
  local suffix = match(str, w .. "$") or match(str, w .. "%s")
  return prefix and suffix
end

return util
