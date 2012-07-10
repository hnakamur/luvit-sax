local exports = {}

local string = require("string")
local sax = require("../sax")

exports["parseStartTag"] = function (test)
  local parser = sax.Parser:new()
  local startTagCount = 0
  parser:on("startTag", function(name)
    startTagCount = startTagCount + 1
    test.equal(name, "DocumentElement")
  end)
  parser:read("<DocumentElement>")
  parser:finish()
  test.equal(startTagCount, 1)
  test.done()
end

exports["parseStartTagWithAttr"] = function (test)
  local parser = sax.Parser:new()
  local startTagCount = 0
  parser:on("startTag", function(name, attrs)
    startTagCount = startTagCount + 1
    test.equal(name, "DocumentElement")
    local attrCount = 0
    for name, value in pairs(attrs) do
      attrCount = attrCount + 1
      test.equal(name, "param")
      test.equal(value, "value")
    end
    test.equal(attrCount, 1)
  end)
  parser:read('<DocumentElement param="value">')
  parser:finish()
  test.equal(startTagCount, 1)
  test.done()
end

exports["parseEndTag"] = function (test)
  local parser = sax.Parser:new()
  local startTagCount = 0
  parser:on("startTag", function(name)
    startTagCount = startTagCount + 1
    test.equal(name, "DocumentElement")
  end)
  local endTagCount = 0
  parser:on("endTag", function(name)
    endTagCount = endTagCount + 1
    test.equal(name, "DocumentElement")
  end)
  parser:read("<DocumentElement>")
  test.equal(startTagCount, 1)
  parser:read("</DocumentElement>")
  test.equal(endTagCount, 1)
  parser:finish()
  test.done()
end

exports["parseEmptyTag"] = function (test)
  local parser = sax.Parser:new()
  local emptyTagCount = 0
  parser:on("emptyTag", function(name)
    emptyTagCount = emptyTagCount + 1
    test.equal(name, "DocumentElement")
  end)
  parser:read("<DocumentElement/>")
  parser:finish()
  test.equal(emptyTagCount, 1)
  test.done()
end

exports["parseEmptyTagWithAttr"] = function (test)
  local parser = sax.Parser:new()
  local emptyTagCount = 0
  parser:on("emptyTag", function(name, attrs)
    emptyTagCount = emptyTagCount + 1
    test.equal(name, "DocumentElement")
    local attrCount = 0
    for name, value in pairs(attrs) do
      attrCount = attrCount + 1
      test.equal(name, "param")
      test.equal(value, "value")
    end
    test.equal(attrCount, 1)
  end)
  parser:read('<DocumentElement param="value" />')
  parser:finish()
  test.equal(emptyTagCount, 1)
  test.done()
end

--exports["parseFull"] = function (test)
--  local parser = sax.Parser:new()
--  parser:read([[<?xml version="1.0" encoding="UTF-8"?>
-- <DocumentElement param="value">
--     <FirstElement>
--         &#b6; Some Text
--     </FirstElement>
--     <?some_pi so]])
--  parser:read([[me_attr="some_value"?>
--     <SecondElement param2="something">
--         Pre-Text <Inline>Inlined text</Inline> Post-text.
--     </SecondElement>
-- </DocumentElement>]])
--  parser:end_()
--  test.done()
--end

return exports
