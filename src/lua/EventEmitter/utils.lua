------------------------------------------------------------------
--
--  Author: Alexey Melnichuk <alexeymelnichuck@gmail.com>
--
--  Copyright (C) 2016 Alexey Melnichuk <alexeymelnichuck@gmail.com>
--
--  Licensed according to the included 'LICENSE' document
--
--  This file is part of lua-EventEmitter library.
--
------------------------------------------------------------------

local function split_first(str, sep, plain)
  local e, e2 = string.find(str, sep, nil, plain)
  if e then
    return string.sub(str, 1, e - 1), string.sub(str, e2 + 1)
  end
  return str
end

local function slit_first_self_test()
  local s1, s2 = split_first("ab|cd", "|", true)
  assert(s1 == "ab")
  assert(s2 == "cd")

  local s1, s2 = split_first("|abcd", "|", true)
  assert(s1 == "")
  assert(s2 == "abcd")

  local s1, s2 = split_first("abcd|", "|", true)
  assert(s1 == "abcd")
  assert(s2 == "")

  local s1, s2 = split_first("abcd", "|", true)
  assert(s1 == "abcd")
  assert(s2 == nil)
end

local function class(base)
  local t = base and setmetatable({}, base) or {}
  t.__index = t
  t.__class = t
  t.__base  = base

  function t.new(...)
    local o = setmetatable({}, t)
    if o.__init then
      if t == ... then -- we call as Class:new()
        return o:__init(select(2, ...))
      else             -- we call as Class.new()
        return o:__init(...)
      end
    end
    return o
  end

  return t
end

local function class_self_test()
  local A = class()
  function A:__init(a, b)
    assert(a == 1)
    assert(b == 2)
  end

  A:new(1, 2)
  A.new(1, 2)

  local B = class(A)

  function B:__init(a,b,c)
    assert(self.__base == A)
    A.__init(B, a, b)
    assert(c == 3)
  end

  B:new(1, 2, 3)
  B.new(1, 2, 3)
end

local function clone(t, o)
  o = o or {}
  for k, v in pairs(t) do
    o[k] = v
  end
  return o
end

local function self_test()
  slit_first_self_test()
  class_self_test()
end

return {
  clone       = clone;
  class       = class;
  split_first = split_first;
  self_test   = self_test;
}
