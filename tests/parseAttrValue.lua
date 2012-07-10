local exports = {}

local string = require("string")
local charset = require("charset")
local sax = require("../sax")

exports["parseAttrValue1"] = function (test)
  local parser = sax.AttrValueParser:new()
  local eventCount = 0
  parser:on("attrValue", function(name)
    eventCount = eventCount + 1
    test.equal(name, "a")
  end)

  local divider = charset.CharDivider:new(charset.utf8)
  divider:on("char", function(char)
    parser:react(char)
  end)
  divider:feed('"a"')
  test.equal(eventCount, 1)
  test.done()
end

exports["parseAttrValue2"] = function (test)
  local parser = sax.AttrValueParser:new()
  local eventCount = 0
  parser:on("attrValue", function(name)
    eventCount = eventCount + 1
    test.equal(name, "ab")
  end)

  local divider = charset.CharDivider:new(charset.utf8)
  divider:on("char", function(char)
    parser:react(char)
  end)
  divider:feed("'ab'")
  test.equal(eventCount, 1)
  test.done()
end

return exports
