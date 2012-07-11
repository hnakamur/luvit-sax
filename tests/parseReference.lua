local exports = {}

local charset = require("charset")
local sax = require("../sax")

exports["parseReference1"] = function (test)
  local parser = sax.ReferenceParser:new()
  local eventCount = 0
  parser:on("reference", function(text, repl)
    eventCount = eventCount + 1
    test.equal(text, "\013")
    test.equal(repl, "&#13;")
  end)

  local divider = charset.CharDivider:new(charset.utf8)
  divider:on("char", function(char)
    parser:react(char)
  end)
  divider:feed('&#13;')
  test.equal(eventCount, 1)
  test.done()
end

exports["parseReference2"] = function (test)
  local parser = sax.ReferenceParser:new()
  local eventCount = 0
  parser:on("reference", function(text, repl)
    eventCount = eventCount + 1
    test.equal(text, "\013")
    test.equal(repl, "&#x0D;")
  end)

  local divider = charset.CharDivider:new(charset.utf8)
  divider:on("char", function(char)
    parser:react(char)
  end)
  divider:feed('&#x0D;')
  test.equal(eventCount, 1)
  test.done()
end

exports["parseReference3"] = function (test)
  local parser = sax.ReferenceParser:new()
  local eventCount = 0
  parser:on("reference", function(text, repl)
    eventCount = eventCount + 1
    test.equal(text, "&")
    test.equal(repl, "&amp;")
  end)

  local divider = charset.CharDivider:new(charset.utf8)
  divider:on("char", function(char)
    parser:react(char)
  end)
  divider:feed('&amp;')
  test.equal(eventCount, 1)
  test.done()
end

return exports
