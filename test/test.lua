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

package.path = "../src/lua/?.lua;" .. package.path

local utils     = require "utils"
local TEST_CASE = require "lunit".TEST_CASE
local ut        = require "EventEmitter.utils"
local em        = require "EventEmitter"

local pcall, error, type, table, ipairs, print = pcall, error, type, table, ipairs, print
local IT, RUN = utils.IT, utils.RUN

local function Counter()
  return setmetatable({{}}, {__call=function(self, name)
    local fn = self[1][name]
    if not fn then
      self[name] = self[name] or 0
      fn = function(inc)
        self[name] = self[name] + (inc or 1)
        return self[name]
      end
      self[1][name] = fn
    end
    return fn
  end})
end

print("------------------------------------")
print("Module    name: " .. em._NAME);
print("Module version: " .. em._VERSION);
print("Lua    version: " .. (_G.jit and _G.jit.version or _G._VERSION))
print("------------------------------------")
print("")

local ENABLE = true

local _ENV = TEST_CASE'EventEmitter self test' if ENABLE then
local it = IT(_ENV or _M)

it('should pass internal test', ut.self_test)

end

local _ENV = TEST_CASE'EventEmitter basic' if ENABLE then
local it = IT(_ENV or _M)

local emitter, counters

function setup()
  emitter = em.EventEmitter.new()
  counters = Counter()
end

function teardown()
  emitter, counters = nil
end

it('should call only once', function()
  emitter:once('A', counters'e0')
  emitter:emit('A')
  assert_equal(1, counters.e0)
  emitter:emit('A')
  assert_equal(1, counters.e0)
end)

it('should call many time', function()
  emitter:on('A', counters'e0')
  for i = 1, 5 do
    emitter:emit('A')
    assert_equal(i, counters.e0)
  end
end)

it('should remove many', function()
  emitter:on('A', counters'e0')
  emitter:emit('A')
  assert_equal(1, counters.e0)

  emitter:off('A', counters'e0')
  emitter:emit('A')
  assert_equal(1, counters.e0)
end)

it('should remove once', function()
  emitter:once('A', counters'e0')
  emitter:off('A', counters'e0')
  emitter:emit('A')
  assert_equal(0, counters.e0)
end)

it('should remove all', function()
  emitter:once('A', counters'e0')
  emitter:on('A',   counters'e1')
  emitter:off('A')
  emitter:emit('A')
  assert_equal(0, counters.e0)
  assert_equal(0, counters.e1)
end)

it('should remove by handler once', function()
  emitter:once('A', counters'e0')
  emitter:on('A',   counters'e1')
  emitter:off('A', counters'e0')
  emitter:emit('A')
  assert_equal(0, counters.e0)
  assert_equal(1, counters.e1)
end)

it('should remove by handler on', function()
  emitter:once('A', counters'e0')
  emitter:on('A',   counters'e1')
  emitter:off('A', counters'e1')
  emitter:emit('A')
  assert_equal(1, counters.e0)
  assert_equal(0, counters.e1)
end)

it('should call multimple subscrabers', function()
  emitter:once('A', counters'e0')
  emitter:on('A',   counters'e1')

  emitter:emit('A')
  assert_equal(1, counters.e0)
  assert_equal(1, counters.e1)

  emitter:emit('A')
  assert_equal(1, counters.e0)
  assert_equal(2, counters.e1)
end)

it('should call any handler', function()
  emitter:once ('A', counters'e0')
  emitter:on   ('A', counters'e1')
  emitter:onAny(     counters'e2')
  emitter:emit('A')
  assert_equal(1, counters.e0)
  assert_equal(1, counters.e1)
  assert_equal(1, counters.e2)
end)

it('should call any handler for unknown event', function()
  emitter:once ('A', counters'e0')
  emitter:on   ('A', counters'e1')
  emitter:onAny(     counters'e2')
  emitter:emit('B')
  assert_equal(0, counters.e0)
  assert_equal(0, counters.e1)
  assert_equal(1, counters.e2)
end)

it('should remove any handler', function()
  emitter:once ('A', counters'e0')
  emitter:on   ('A', counters'e1')
  emitter:onAny(     counters'e2')
  emitter:offAny(    counters'e2')
  emitter:emit('A')
  assert_equal(1, counters.e0)
  assert_equal(1, counters.e1)
  assert_equal(0, counters.e2)
end)

it('should call any handler only once', function()
  emitter:once   ('A', counters'e0')
  emitter:on     ('A', counters'e1')
  emitter:onceAny(     counters'e2')

  emitter:emit('A')
  assert_equal(1, counters.e0)
  assert_equal(1, counters.e1)
  assert_equal(1, counters.e2)

  emitter:emit('A')
  assert_equal(1, counters.e0)
  assert_equal(2, counters.e1)
  assert_equal(1, counters.e2)
end)

it('should remove once any handler', function()
  emitter:once   ('A', counters'e0')
  emitter:on     ('A', counters'e1')
  emitter:onceAny(     counters'e2')
  emitter:offAny(      counters'e2')

  emitter:emit('A')
  assert_equal(1, counters.e0)
  assert_equal(1, counters.e1)
  assert_equal(0, counters.e2)
end)

end

local _ENV = TEST_CASE'EventEmitter tree' if ENABLE then
local it = IT(_ENV or _M)

local emitter, counters

function setup()
  emitter = em.TreeEventEmitter.new('::')
  counters = Counter()
end

function teardown()
  emitter, counters = nil
end

it('should match only base', function()
  emitter:on('A',    counters'e0')
  emitter:on('A::*', counters'e1')
  emitter:emit('A')
  assert_equal(1, counters.e0)
  assert_equal(0, counters.e1)
end)

it('should match only subclass', function()
  emitter:on('A',    counters'e0')
  emitter:on('A::*', counters'e1')
  emitter:emit('A::1')
  assert_equal(0, counters.e0)
  assert_equal(1, counters.e1)
end)

it('should match only subclass 2', function()
  emitter:on('A',       counters'e0')
  emitter:on('A::*',    counters'e1')
  emitter:on('A::1::*', counters'e2')
  emitter:emit('A::1::2')
  assert_equal(0, counters.e0)
  assert_equal(0, counters.e1)
  assert_equal(1, counters.e2)
end)

it('should match whildcard in the middle of emit', function()
  emitter:on('A',       counters'e0')
  emitter:on('A::*',    counters'e1')
  emitter:on('A::B',    counters'e2')
  emitter:on('A::B::C', counters'e3')
  emitter:on('A::B::*', counters'e4')
  emitter:on('A::*::C', counters'e5')

  emitter:emit('A::*::C')

  assert_equal(0, counters.e0)
  assert_equal(0, counters.e1)
  assert_equal(0, counters.e2)
  assert_equal(1, counters.e3)
  assert_equal(1, counters.e4)
  assert_equal(1, counters.e5)
end)

it('should match whildcard in the end of emit', function()
  emitter:on('A',       counters'e0')
  emitter:on('A::*',    counters'e1')
  emitter:on('A::B',    counters'e2')
  emitter:on('A::B::C', counters'e3')
  emitter:on('A::B::*', counters'e4')
  emitter:on('A::*::C', counters'e5')

  emitter:emit('A::*')

  assert_equal(0, counters.e0)
  assert_equal(1, counters.e1)
  assert_equal(1, counters.e2)
  assert_equal(0, counters.e3)
  assert_equal(0, counters.e4)
  assert_equal(0, counters.e5)
end)

it('should match whildcard at level', function()
  emitter:on('A',       counters'e0')
  emitter:on('A::*',    counters'e1')
  emitter:on('A::B',    counters'e2')
  emitter:on('A::B::C', counters'e3')
  emitter:on('A::B::*', counters'e4')
  emitter:on('A::*::C', counters'e5')

  emitter:emit('A::*::*')

  assert_equal(0, counters.e0)
  assert_equal(0, counters.e1)
  assert_equal(0, counters.e2)
  assert_equal(1, counters.e3)
  assert_equal(1, counters.e4)
  assert_equal(1, counters.e5)
end)

it('should calls handle only once', function()
  emitter:on('A',    counters'e0')
  emitter:on('A',    counters'e0')
  emitter:on('A::*', counters'e0')
  emitter:on('A::*', counters'e0')
  emitter:emit('A')
  assert_equal(1, counters.e0)
end)

it('should match top wildcard', function()
  emitter:on('*',   counters'e0')
  emitter:on('::*', counters'e1')

  emitter:emit('A')
  assert_equal(1, counters.e0)
  assert_equal(0, counters.e1)

  emitter:emit('A::B')
  assert_equal(1, counters.e0)
  assert_equal(0, counters.e1)
end)

it('shold ignore unmatched', function()
  emitter:on('A::*', counters'e0')
  emitter:emit('B')
  assert_equal(0, counters.e0)
  emitter:off('A::*', counters'e0')

  emitter:on('A::B::*', counters'e0')
  emitter:emit('A::C')
  assert_equal(0, counters.e0)
  emitter:off('A::B::*', counters'e0')

  emitter:on('A::B::C::*', counters'e0')
  emitter:emit('B::C')
  assert_equal(0, counters.e0)
  emitter:off('A::B::C::*', counters'e0')
end)

end

local _ENV = TEST_CASE'EventEmitter tree recur' if ENABLE then
local it = IT(_ENV or _M)

local emitter, counters

function setup()
  emitter = em.EventEmitter.new{wildcard = true; delimiter = '::'}
  counters = Counter()
end

function teardown()
  emitter, counters = nil
end

it('should match end char', function()
  emitter:on('A',        counters'e0');
  emitter:on('A::*',     counters'e1');
  emitter:on('A::**',    counters'e2');
  emitter:on('A::**::C', counters'e3');
  emitter:emit('A::B::C')

  assert_equal(0, counters.e0)
  assert_equal(0, counters.e1)
  assert_equal(1, counters.e2)
  assert_equal(1, counters.e3)
end)

it('should match empty string as wildcard', function()
  emitter:on('A',        counters'e0');
  emitter:on('A::*',     counters'e1');
  emitter:on('A::**',    counters'e2');
  emitter:on('A::**::C', counters'e3');
  emitter:emit('A::C')

  assert_equal(0, counters.e0)
  assert_equal(1, counters.e1)
  assert_equal(1, counters.e2)
  assert_equal(1, counters.e3)
end)

it('should match wildcard in events', function()
  emitter:on('A',        counters'e0');
  emitter:on('A::*',     counters'e1');
  emitter:on('A::**',    counters'e2');
  emitter:on('A::**::C', counters'e3');
  emitter:emit('A::*')

  assert_equal(0, counters.e0)
  assert_equal(1, counters.e1)
  assert_equal(1, counters.e2)
  assert_equal(0, counters.e3)
end)

it('test 1', function()
  emitter:on('A',          counters'e0');
  emitter:on('A::*',       counters'e1');
  emitter:on('A::**',      counters'e2');
  emitter:on('A::**::B',   counters'e3');
  emitter:on('A::**::B::C',counters'e4');
  emitter:emit('A::B::C')

  assert_equal(0, counters.e0)
  assert_equal(0, counters.e1)
  assert_equal(1, counters.e2)
  assert_equal(0, counters.e3)
  assert_equal(1, counters.e4)
end)

it('test 2', function()
  emitter:on('A',          counters'e0');
  emitter:on('A::*',       counters'e1');
  emitter:on('A::**',      counters'e2');
  emitter:on('A::**::B',   counters'e3');
  emitter:on('A::**::B::C',counters'e4');
  emitter:emit('A::G::B::C')

  assert_equal(0, counters.e0)
  assert_equal(0, counters.e1)
  assert_equal(1, counters.e2)
  assert_equal(0, counters.e3)
  assert_equal(1, counters.e4)
end)

it('test 3', function()
  emitter:on('A',          counters'e0');
  emitter:on('A::*',       counters'e1');
  emitter:on('A::**',      counters'e2');
  emitter:on('A::**::B',   counters'e3');
  emitter:on('A::**::B::*',counters'e4');
  emitter:emit('A::B::C')

  assert_equal(0, counters.e0)
  assert_equal(0, counters.e1)
  assert_equal(1, counters.e2)
  assert_equal(0, counters.e3)
  assert_equal(1, counters.e4)
end)

it('test 4', function()
  emitter:on('**',         counters'e0');
  emitter:on('::**',       counters'e1');
  emitter:emit('A')

  assert_equal(1, counters.e0)
  assert_equal(0, counters.e1)
end)

end

RUN()
