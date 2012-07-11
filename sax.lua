local charset = require("charset")
local string = require("string")
local table = require("table")
local Object = require("core").Object
local hsm = require("hsm")
local StateMachine = hsm.StateMachine
local HierarchicalStateMachine = hsm.HierarchicalStateMachine

local sax = {}

local StringBuilder = Object:extend()

function StringBuilder:initialize()
  self.texts = {}
end

function StringBuilder:isEmpty()
  return #self.texts == 0
end

function StringBuilder:append(text)
  if text and #text > 0 then
    table.insert(self.texts, text)
  end
end

function StringBuilder:flush()
  local text = table.concat(self.texts, "")
  self.texts = {}
  return text
end

function isSpaceChar(c)
  return c == " " or c == "\t" or c == "\n" or c == "\r"
end

function isNameStartChar(c)
  if #c == 1 then
    -- TODO: follow the spec
    return ("a" <= c and c <= "z") or
      ("A" <= c and c <= "Z") or c == "_" or c == ":"
  else
    -- TODO: follow the spec
    return false
  end
end

function isDigitChar(c)
  return "0" <= c and c <= "9"
end

function isHexDigitChar(c)
  return "0" <= c and c <= "9"
    or "A" <= c and c <= "F"
    or "a" <= c and c <= "f"
end

function isNameChar(c)
  if isNameStartChar(c) then return true end
  if #c == 1 then
    return ("0" <= c and c <= "9") or c == "-" or c == "." or c == "\183"
  else
    -- TODO: follow the spec
    return false
  end
end

local NameParser = StateMachine:extend()

function NameParser:initialize()
  self:defineStates{
    Init = {},
    Head = {},
    Tail = {}
  }
  self.state = self.states.Init
  self.buffer = {}
end

function NameParser:_reactInit(c)
  if isNameStartChar(c) then
    table.insert(self.buffer, c)
    return self.states.Head
  end
end

function NameParser:_handleNameChar(c)
  if isNameChar(c) then
    table.insert(self.buffer, c)
    return self.states.Tail
  else
    self:emit("name", table.concat(self.buffer, ""))
    self.buffer = {}
    self:_transit(self.states.Init)
    -- return nil because we do not handle the input c
  end
end

function NameParser:_reactHead(c)
  return self:_handleNameChar(c)
end

function NameParser:_reactTail(c)
  return self:_handleNameChar(c)
end

function NameParser:finish()
  if #self.buffer > 0 then
    self:emit("name", table.concat(self.buffer, ""))
    self.buffer = {}
    self:_transit(self.states.Init)
  end
end

local AttrValueParser = StateMachine:extend()

function AttrValueParser:initialize()
  self:defineStates{
    Init = {},
    Value = {}
  }
  self.state = self.states.Init
  self.buffer = {}
end

function AttrValueParser:_reactInit(c)
  if c == '"' or c == "'" then
    self.quote = c
    return self.states.Value
  end
end

function AttrValueParser:_reactValue(c)
  if c == self.quote then
    local attrValue = table.concat(self.buffer, "")
    self.buffer = {}
    self:emit("attrValue", attrValue)
    return self.states.Init
  end

  -- TODO: handle entity reference like &amp; or &#14.
  table.insert(self.buffer, c)
end

local ReferenceParser = StateMachine:extend()

ReferenceParser.entityMap = {
  amp = "&",
  lt = "<"
}

function ReferenceParser:initialize()
  self:defineStates{
    Init = {},
    SeenAmp = {},
    SeenSharp = {},
    DecCharRef = {},
    HexCharRef = {},
    EntityRef = {},
  }
  self.state = self.states.Init
  self.buffer = {}
end

function ReferenceParser:_reactInit(c)
  if c == "&" then
    return self.states.SeenAmp
  end
end

function ReferenceParser:_reactSeenAmp(c)
  if c == "#" then
    return self.states.SeenSharp
  end

  if not self.nameParser then
    self.nameParser = NameParser:new()
    self.nameParser:on("name", function(name)
      self.entityName = name
    end)
  end
  if self.nameParser:react(c) then
    return self.states.EntityRef
  end
end

function ReferenceParser:_reactSeenSharp(c)
  if c == "x" then
    return self.states.HexCharRef
  end

  if isDigitChar(c) then
    table.insert(self.buffer, c)
    return self.states.DecCharRef
  end
end

function ReferenceParser:_reactDecCharRef(c)
  if isDigitChar(c) then
    table.insert(self.buffer, c)
    return self.states.DecCharRef
  end

  if c == ";" then
    local decText = table.concat(self.buffer, "")
    self.buffer = {}
    local code = tonumber(decText)
    -- TODO: convert UTF-16 to UTF-8
    local text = string.char(code)
    self:emit("reference", text, "&#" .. decText .. ";")
  end
end

function ReferenceParser:_reactHexCharRef(c)
  if isHexDigitChar(c) then
    table.insert(self.buffer, c)
    return self.states.HexCharRef
  end

  if c == ";" then
    local hexText = table.concat(self.buffer, "")
    self.buffer = {}
    local code = tonumber(hexText, 16)
    -- TODO: convert UTF-16 to UTF-8
    local text = string.char(code)
    self:emit("reference", text, "&#x" .. hexText .. ";")
  end
end

function ReferenceParser:_reactEntityRef(c)
  if self.nameParser:react(c) then
    return self.states.EntityRef
  end

  if c == ";" then
    local text = ReferenceParser.entityMap[self.entityName]
    self:emit("reference", text, "&" .. self.entityName .. ";")
  end
end

function ReferenceParser:finish()
  -- TODO: emit error
end


local Parser = HierarchicalStateMachine:extend()

function Parser:initialize()
  self:defineStates{
    Init = {},
    SeenLT = {},
    StartTag = {
      StartTagName = {},
      SpacesAfterStartTagName = {},
      AttrName = {},
      AttrEqual = {},
      AttrValue = {}
    },
    EmptyTag = {},
    EndTag = {}
  }
  self.state = self.states.Init

  self.divider = charset.CharDivider:new(charset.utf8)
  self.divider:on("char", function(char)
    self:react(char)
  end)

  self.contentBuilder = StringBuilder:new()
end

function Parser:read(data)
  self.divider:feed(data)
end

function Parser:finish()
end

function Parser:_reactInit(c)
  if c == '<' then
    if not self.contentBuilder:isEmpty() then
      self:emit("content", self.contentBuilder:flush())
    end
    return self.states.SeenLT
  end

  self.contentBuilder:append(c)
end

function Parser:_entrySeenLT()
  self.nameParser = NameParser:new()
  self.nameParser:on("name", function(name)
    self.tagName = name
    self.attrs = {}
  end)
end

function Parser:_reactSeenLT(c)
  local state = self.nameParser:react(c)
  if state then
  --if self.nameParser:react(c) then
    return self.states.StartTagName
  end

  if c == '/' then
    return self.states.EndTag
  end
end

function Parser:_reactStartTagName(c)
  if self.nameParser:react(c) then
    return self.states.StartTagName
  end

  if isSpaceChar(c) then
    return self.states.SpacesAfterStartTagName
  end
end

function Parser:_entrySpacesAfterStartTagName()
  self.nameParser = NameParser:new()
  self.nameParser:on("name", function(name)
    self.attrName = name
  end)
end

function Parser:_reactSpacesAfterStartTagName(c)
  if self.nameParser:react(c) then
    return self.states.AttrName
  end

  if isSpaceChar(char) then
    return self.states.SpacesAfterStartTagName
  end
end

function Parser:_reactAttrName(c)
  if self.nameParser:react(c) then
    return self.states.AttrName
  end

  if c == "=" then
    return self.states.AttrEqual
  end
end

function Parser:_entryAttrEqual()
  self.attrValueParser = AttrValueParser:new()
  self.attrValueParser:on("attrValue", function(value)
    self.attrs[self.attrName] = value
  end)
end

function Parser:_reactAttrEqual(c)
  if self.attrValueParser:react(c) then
    return self.states.AttrValue
  end
end

function Parser:_reactAttrValue(c)
  if self.attrValueParser:react(c) then
    return self.states.AttrValue
  end
end

function Parser:_reactStartTag(c)
  if c == '>' then
    self:emit("startTag", self.tagName, self.attrs)
    return self.states.Init
  end

  if c == '/' then
    return self.states.EmptyTag
  end
end

function Parser:_reactEmptyTag(c)
  if c == '>' then
    self:emit("emptyTag", self.tagName, self.attrs)
    return self.states.Init
  end
end

function Parser:_entryEndTag()
  self.nameParser = NameParser:new()
  self.nameParser:on("name", function(name)
    self.tagName = name
  end)
end

function Parser:_reactEndTag(c)
  if self.nameParser:react(c) then
    return self.states.EndTag
  end

  if isSpaceChar(c) then
    return self.states.EndTag
  end

  if c == '>' then
    self:emit("endTag", self.tagName)
    return self.states.Init
  end
end

sax.NameParser = NameParser
sax.AttrValueParser = AttrValueParser
sax.ReferenceParser = ReferenceParser
sax.Parser = Parser
return sax
