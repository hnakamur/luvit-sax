local exports = {}

local string = require("string")
local sax = require("../sax")

exports["parseName1"] = function (test)
  local parser = sax.NameParser:new()
  local nameEventCount = 0
  parser:on("name", function(name)
    nameEventCount = nameEventCount + 1
    test.equal(name, "a")
  end)
  parser:react("a")
  test.equal(parser:react(" "), nil)
  test.equal(nameEventCount, 1)
  test.done()
end

exports["parseName2"] = function (test)
  local parser = sax.NameParser:new()
  local nameEventCount = 0
  parser:on("name", function(name)
    nameEventCount = nameEventCount + 1
    test.equal(name, "ab")
  end)
  parser:react("a")
  parser:react("b")
  test.equal(parser:react(" "), nil)
  test.equal(nameEventCount, 1)
  test.done()
end

exports["parseName3"] = function (test)
  local parser = sax.NameParser:new()
  local nameEventCount = 0
  parser:on("name", function(name)
    nameEventCount = nameEventCount + 1
    test.equal(name, "ab")
  end)
  parser:react("a")
  parser:react("b")
  test.equal(parser:finish(), nil)
  test.equal(nameEventCount, 1)
  test.done()
end

exports["parseName4"] = function (test)
  local parser = sax.NameParser:new()
  local nameEventCount = 0
  parser:on("name", function(name)
    nameEventCount = nameEventCount + 1
    test.equal(name, "ab")
  end)
  parser:react("a")
  parser:react("b")
  test.equal(parser:react(" "), nil)
  test.equal(nameEventCount, 1)
  test.equal(parser:finish(), nil)
  test.equal(nameEventCount, 1)
  test.done()
end

return exports
