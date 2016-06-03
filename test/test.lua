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

pcall(require, "luacov")

local utils        = require "utils"
local TEST_CASE    = require "lunit".TEST_CASE
local ut           = require "EventEmitter.utils"
local EventEmitter = require "EventEmitter"

local pcall, error, type, table, ipairs, print, next = pcall, error, type, table, ipairs, print, next
local IT, RUN = utils.IT, utils.RUN

local function Counter()
  return setmetatable({{}}, {__call=function(self, name)
    local fn = self[1][name]
    if not fn then
      self[name] = self[name] or 0
      fn = function(inc)
        self[name] = self[name] + 1
        return self[name]
      end
      self[1][name] = fn
    end
    return fn
  end})
end

local function dummy()end

print("------------------------------------")
print("Module    name: " .. EventEmitter._NAME);
print("Module version: " .. EventEmitter._VERSION);
print("Lua    version: " .. (_G.jit and _G.jit.version or _G._VERSION))
print("------------------------------------")
print("")

local ENABLE = true

local _ENV = TEST_CASE'EventEmitter self test' if ENABLE then
local it = IT(_ENV or _M)

it('should pass internal test', ut.self_test)

end

local _ENV = TEST_CASE'EventEmitter API' if ENABLE then
local it = IT(_ENV or _M)

local counters

function setup()
  emitter = EventEmitter.new()
  counters = Counter()
end

it('module should has API', function()
  assert(EventEmitter)
  assert_function(EventEmitter.extend)
  assert_function(EventEmitter.extend_class)
  assert_function(EventEmitter.extend_object)
  assert_function(EventEmitter.new)
  assert_string(EventEmitter._NAME)
  assert_string(EventEmitter._VERSION)
end)

it('emitter should has API', function()
  assert_function(emitter.once)
  assert_function(emitter.on)
  assert_function(emitter.off)
  assert_function(emitter.many)
  assert_function(emitter.onAny)
  assert_function(emitter.offAny)
  assert_function(emitter.onceAny)
  assert_function(emitter.manyAny)
  assert_function(emitter.addListener)
  assert_function(emitter.removeListener)
  assert_function(emitter.removeAllListeners)
end)

it('should pass self and event', function()
  emitter = EventEmitter.new{wildcard=true}

  emitter:on('A.*', function(self, event, value)
    counters('e0')()
    assert_equal(emitter, self)
    assert_equal('A.B',   event)
    assert_equal('hello', value)
  end)

  emitter:onAny(function(self, event, value)
    counters('e1')()
    assert_equal(emitter, self)
    assert_equal('A.B',   event)
    assert_equal('hello', value)
  end)

  assert_true(emitter:emit('A.B', 'hello'))

  assert_equal(1, counters.e0)
  assert_equal(1, counters.e1)
end)

it('should pass self and event with wildcard', function()
  emitter:on('A', function(self, event, value)
    counters('e0')()
    assert_equal(emitter, self)
    assert_equal('A',     event)
    assert_equal('hello', value)
  end)

  emitter:onAny(function(self, event, value)
    counters('e1')()
    assert_equal(emitter, self)
    assert_equal('A',     event)
    assert_equal('hello', value)
  end)

  assert_true(emitter:emit('A', 'hello'))

  assert_equal(1, counters.e0)
  assert_equal(1, counters.e1)
end)

it('emit should pass custom self', function()
  emitter = EventEmitter.new{self = 'hello'}

  emitter:once ('A', function(self)
    assert_equal('hello', self)
    counters'e0'()
  end)
  emitter:on   ('A', function(self)
    assert_equal('hello', self)
    counters'e1'()
  end)
  assert_true(emitter:emit('A'))
  assert_equal(1, counters.e0)
  assert_equal(1, counters.e1)
end)

it('`emit` should not accept invalid args', function()
  assert_error('no args'        , function() emitter:on()    end        )
end)

it('`on` should not accept invalid args', function()
  assert_error('no args'        , function() emitter:on()    end        )
  assert_error('no listner'     , function() emitter:on('A') end        )
  assert_error('no event'       , function() emitter:on(nil, dummy) end )
  assert_error('invalid listner', function() emitter:on('A', 'B') end   )
end)

it('`onAny` should not accept invalid args', function()
  assert_error('no args'        , function() emitter:onAny()    end        )
  assert_error('no listner'     , function() emitter:onAny('A') end        )
  assert_error('no event'       , function() emitter:onAny(nil, dummy) end )
  assert_error('invalid listner', function() emitter:onAny('A', 'B') end   )
end)

it('`once` should not accept invalid args', function()
  assert_error('no args'        , function() emitter:once()    end        )
  assert_error('no listner'     , function() emitter:once('A') end        )
  assert_error('no event'       , function() emitter:once(nil, dummy) end )
  assert_error('invalid listner', function() emitter:once('A', 'B') end   )
end)

it('`onceAny` should not accept invalid args', function()
  assert_error('no args'        , function() emitter:onceAny()    end        )
  assert_error('no listner'     , function() emitter:onceAny('A') end        )
  assert_error('no event'       , function() emitter:onceAny(nil, dummy) end )
  assert_error('invalid listner', function() emitter:onceAny('A', 'B') end   )
end)

it('`many` should not accept invalid args', function()
  assert_error('no args'        , function() emitter:many()       end            )
  assert_error('no ttl'         , function() emitter:many('A', nil, dummy) end   )
  assert_error('invalid ttl'    , function() emitter:many('A', '1', dummy) end   )
  assert_error('omit ttl'       , function() emitter:many('A', dummy) end        )
  assert_error('no listner'     , function() emitter:many('A', 1) end            )
  assert_error('no event'       , function() emitter:many(nil, 1, dummy) end     )
  assert_error('invalid listner', function() emitter:many('A', 1, 'B') end       )
end)

it('`manyAny` should not accept invalid args', function()
  assert_error('no args'        , function() emitter:manyAny()       end            )
  assert_error('no ttl'         , function() emitter:manyAny('A', nil, dummy) end   )
  assert_error('invalid ttl'    , function() emitter:manyAny('A', '1', dummy) end   )
  assert_error('omit ttl'       , function() emitter:manyAny('A', dummy) end        )
  assert_error('no listner'     , function() emitter:manyAny('A', 1) end            )
  assert_error('no event'       , function() emitter:manyAny(nil, 1, dummy) end     )
  assert_error('invalid listner', function() emitter:manyAny('A', 1, 'B') end       )
end)

end

local _ENV = TEST_CASE'EventEmitter basic' if ENABLE then
local it = IT(_ENV or _M)

local emitter, counters

function setup()
  emitter = EventEmitter.new()
  counters = Counter()
end

function teardown()
  emitter, counters = nil
end

it('should call only once', function()
  emitter:once('A', counters'e0')
  assert_true(emitter:emit('A'))
  assert_equal(1, counters.e0)
  assert_false(emitter:emit('A'))
  assert_equal(1, counters.e0)
end)

it('should call many time', function()
  emitter:on('A', counters'e0')
  for i = 1, 5 do
    assert_true(emitter:emit('A'))
    assert_equal(i, counters.e0)
  end
end)

it('should remove many', function()
  emitter:on('A', counters'e0')
  assert_true(emitter:emit('A'))
  assert_equal(1, counters.e0)

  emitter:off('A', counters'e0')
  assert_false(emitter:emit('A'))
  assert_equal(1, counters.e0)
end)

it('should remove once', function()
  emitter:once('A', counters'e0')
  emitter:once('A', counters'e1')
  emitter:off('A', counters'e0')
  assert_true(emitter:emit('A'))
  assert_equal(0, counters.e0)
  assert_equal(1, counters.e1)
end)

it('should remove all', function()
  emitter:once('A', counters'e0')
  emitter:on('A',   counters'e1')
  emitter:off('A')
  assert_false(emitter:emit('A'))
  assert_equal(0, counters.e0)
  assert_equal(0, counters.e1)
end)

it('should remove by handler once', function()
  emitter:once('A', counters'e0')
  emitter:on('A',   counters'e1')
  emitter:off('A', counters'e0')
  assert_true(emitter:emit('A'))
  assert_equal(0, counters.e0)
  assert_equal(1, counters.e1)
end)

it('should remove by handler on', function()
  emitter:once('A', counters'e0')
  emitter:on('A',   counters'e1')
  emitter:off('A', counters'e1')
  assert_true(emitter:emit('A'))
  assert_equal(1, counters.e0)
  assert_equal(0, counters.e1)
end)

it('should call multimple subscrabers', function()
  emitter:once('A', counters'e0')
  emitter:on('A',   counters'e1')

  assert_true(emitter:emit('A'))
  assert_equal(1, counters.e0)
  assert_equal(1, counters.e1)

  assert_true(emitter:emit('A'))
  assert_equal(1, counters.e0)
  assert_equal(2, counters.e1)
end)

it('should call any handler', function()
  emitter:once ('A', counters'e0')
  emitter:on   ('A', counters'e1')
  emitter:onAny(     counters'e2')
  assert_true(emitter:emit('A'))
  assert_equal(1, counters.e0)
  assert_equal(1, counters.e1)
  assert_equal(1, counters.e2)
end)

it('should call any handler for unknown event', function()
  emitter:once ('A', counters'e0')
  emitter:on   ('A', counters'e1')
  emitter:onAny(     counters'e2')
  assert_true(emitter:emit('B'))
  assert_equal(0, counters.e0)
  assert_equal(0, counters.e1)
  assert_equal(1, counters.e2)
end)

it('should remove any handler', function()
  emitter:once ('A', counters'e0')
  emitter:on   ('A', counters'e1')
  emitter:onAny(     counters'e2')
  emitter:offAny(    counters'e2')
  assert_true(emitter:emit('A'))
  assert_equal(1, counters.e0)
  assert_equal(1, counters.e1)
  assert_equal(0, counters.e2)
end)

it('should call any handler only once', function()
  emitter:once   ('A', counters'e0')
  emitter:on     ('A', counters'e1')
  emitter:onceAny(     counters'e2')

  assert_true(emitter:emit('A'))
  assert_equal(1, counters.e0)
  assert_equal(1, counters.e1)
  assert_equal(1, counters.e2)

  assert_true(emitter:emit('A'))
  assert_equal(1, counters.e0)
  assert_equal(2, counters.e1)
  assert_equal(1, counters.e2)
end)

it('should remove once any handler', function()
  emitter:once   ('A', counters'e0')
  emitter:on     ('A', counters'e1')
  emitter:onceAny(     counters'e2')
  emitter:offAny(      counters'e2')

  assert_true(emitter:emit('A'))
  assert_equal(1, counters.e0)
  assert_equal(1, counters.e1)
  assert_equal(0, counters.e2)
end)

end

local _ENV = TEST_CASE'EventEmitter tree' if ENABLE then
local it = IT(_ENV or _M)

local emitter, counters

function setup()
  emitter = EventEmitter.new{wildcard=true, delimiter = '::'}
  counters = Counter()
end

function teardown()
  emitter, counters = nil
end

it('should match only base', function()
  emitter:on('A',    counters'e0')
  emitter:on('A::*', counters'e1')
  assert_true(emitter:emit('A'))
  assert_equal(1, counters.e0)
  assert_equal(0, counters.e1)
end)

it('should match only subclass', function()
  emitter:on('A',    counters'e0')
  emitter:on('A::*', counters'e1')
  assert_true(emitter:emit('A::1'))
  assert_equal(0, counters.e0)
  assert_equal(1, counters.e1)
end)

it('should match only subclass 2', function()
  emitter:on('A',       counters'e0')
  emitter:on('A::*',    counters'e1')
  emitter:on('A::1::*', counters'e2')
  assert_true(emitter:emit('A::1::2'))
  assert_equal(0, counters.e0)
  assert_equal(0, counters.e1)
  assert_equal(1, counters.e2)
end)

it('should match wildcard in the middle of emit', function()
  emitter:on('A',       counters'e0')
  emitter:on('A::*',    counters'e1')
  emitter:on('A::B',    counters'e2')
  emitter:on('A::B::C', counters'e3')
  emitter:on('A::B::*', counters'e4')
  emitter:on('A::*::C', counters'e5')

  assert_true(emitter:emit('A::*::C'))

  assert_equal(0, counters.e0)
  assert_equal(0, counters.e1)
  assert_equal(0, counters.e2)
  assert_equal(1, counters.e3)
  assert_equal(1, counters.e4)
  assert_equal(1, counters.e5)
end)

it('should match wildcard in the end of emit', function()
  emitter:on('A',       counters'e0')
  emitter:on('A::*',    counters'e1')
  emitter:on('A::B',    counters'e2')
  emitter:on('A::B::C', counters'e3')
  emitter:on('A::B::*', counters'e4')
  emitter:on('A::*::C', counters'e5')

  assert_true(emitter:emit('A::*'))

  assert_equal(0, counters.e0)
  assert_equal(1, counters.e1)
  assert_equal(1, counters.e2)
  assert_equal(0, counters.e3)
  assert_equal(0, counters.e4)
  assert_equal(0, counters.e5)
end)

it('should match wildcard at level', function()
  emitter:on('A',       counters'e0')
  emitter:on('A::*',    counters'e1')
  emitter:on('A::B',    counters'e2')
  emitter:on('A::B::C', counters'e3')
  emitter:on('A::B::*', counters'e4')
  emitter:on('A::*::C', counters'e5')

  assert_true(emitter:emit('A::*::*'))

  assert_equal(0, counters.e0)
  assert_equal(0, counters.e1)
  assert_equal(0, counters.e2)
  assert_equal(1, counters.e3)
  assert_equal(1, counters.e4)
  assert_equal(1, counters.e5)
end)

it('should count events with wildcard', function()
  emitter:many('A',       1, counters'e0')
  emitter:many('A::*',    1, counters'e1')
  emitter:many('A::B',    1, counters'e2')
  emitter:many('A::B::C', 1, counters'e3')
  emitter:many('A::B::*', 2, counters'e4')
  emitter:many('A::*::C', 3, counters'e5')

  assert_true(emitter:emit('A::B::*'))
  assert_true(emitter:emit('A::*::*'))
  assert_true(emitter:emit('A::*::C'))
  assert_false(emitter:emit('A::B::C'))

  assert_equal(0, counters.e0)
  assert_equal(0, counters.e1)
  assert_equal(0, counters.e2)
  assert_equal(1, counters.e3)
  assert_equal(2, counters.e4)
  assert_equal(3, counters.e5)
end)

it('should count any events', function()
  emitter:manyAny(1, counters'e0')
  emitter:manyAny(2, counters'e1')
  emitter:manyAny(3, counters'e2')

  assert_true(emitter:emit('A'))
  assert_true(emitter:emit('B'))
  assert_true(emitter:emit('C'))
  assert_false(emitter:emit('D'))

  assert_equal(1, counters.e0)
  assert_equal(2, counters.e1)
  assert_equal(3, counters.e2)
end)

it('should calls handle only once', function()
  emitter:on('A',    counters'e0')
  emitter:on('A',    counters'e0')
  emitter:on('A::*', counters'e0')
  emitter:on('A::*', counters'e0')
  assert_true(emitter:emit('A'))
  assert_equal(1, counters.e0)
end)

it('should remove once listners', function()
  emitter:once('A',    counters'e0')
  assert_true(emitter:emit('A'))
  assert_equal(1, counters.e0)
  assert_false(emitter:emit('A'))
  assert_equal(1, counters.e0)
end)

it('should remove onceAny listners', function()
  emitter:onceAny(counters'e0')
  assert_true(emitter:emit('A'))
  assert_equal(1, counters.e0)
  assert_false(emitter:emit('A'))
  assert_equal(1, counters.e0)
end)

it('should remove many listners', function()
  emitter:many('A', 2, counters'e0')
  assert_true(emitter:emit('A'))
  assert_equal(1, counters.e0)
  assert_true(emitter:emit('A'))
  assert_equal(2, counters.e0)
  assert_false(emitter:emit('A'))
  assert_equal(2, counters.e0)
end)

it('should remove manyAny listners', function()
  emitter:manyAny(2, counters'e0')
  assert_true(emitter:emit('A'))
  assert_equal(1, counters.e0)
  assert_true(emitter:emit('A'))
  assert_equal(2, counters.e0)
  assert_false(emitter:emit('A'))
  assert_equal(2, counters.e0)
end)

it('should match top wildcard', function()
  emitter:on('*',   counters'e0')
  emitter:on('::*', counters'e1')

  assert_true(emitter:emit('A'))
  assert_equal(1, counters.e0)
  assert_equal(0, counters.e1)

  assert_false(emitter:emit('A::B'))
  assert_equal(1, counters.e0)
  assert_equal(0, counters.e1)
end)

it('should ignore unmatched', function()
  emitter:on('A::*', counters'e0')
  assert_false(emitter:emit('B'))
  assert_equal(0, counters.e0)
  emitter:off('A::*', counters'e0')

  emitter:on('A::B::*', counters'e0')
  assert_false(emitter:emit('A::C'))
  assert_equal(0, counters.e0)
  emitter:off('A::B::*', counters'e0')

  emitter:on('A::B::C::*', counters'e0')
  assert_false(emitter:emit('B::C'))
  assert_equal(0, counters.e0)
  emitter:off('A::B::C::*', counters'e0')
end)

end

local _ENV = TEST_CASE'EventEmitter tree recur' if ENABLE then
local it = IT(_ENV or _M)

local emitter, counters

function setup()
  emitter = EventEmitter.new{wildcard = true; delimiter = '::'}
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
  assert_true(emitter:emit('A::B::C'))

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
  assert_true(emitter:emit('A::C'))

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

  assert_true(emitter:emit('A::*'))
  assert_equal(0, counters.e0)
  assert_equal(1, counters.e1)
  assert_equal(1, counters.e2)
  assert_equal(1, counters.e3)

  assert_true(emitter:emit('A::C'))
  assert_equal(0, counters.e0)
  assert_equal(2, counters.e1)
  assert_equal(2, counters.e2)
  assert_equal(2, counters.e3)

  assert_true(emitter:emit('A::*::C'))
  assert_equal(0, counters.e0)
  assert_equal(2, counters.e1)
  assert_equal(3, counters.e2)
  assert_equal(3, counters.e3)
end)

it('should match prefix with wildcard in events', function()
  emitter:on('A',        counters'e0');
  emitter:on('A::*',     counters'e1');
  emitter:on('A::**',    counters'e2');
  emitter:on('A::**::C', counters'e3');

  assert_false(emitter:emit('B::*'))
  assert_equal(0, counters.e0)
  assert_equal(0, counters.e1)
  assert_equal(0, counters.e2)
  assert_equal(0, counters.e3)

  assert_false(emitter:emit('B::C'))
  assert_equal(0, counters.e0)
  assert_equal(0, counters.e1)
  assert_equal(0, counters.e2)
  assert_equal(0, counters.e3)

  assert_false(emitter:emit('B::*::C'))
  assert_equal(0, counters.e0)
  assert_equal(0, counters.e1)
  assert_equal(0, counters.e2)
  assert_equal(0, counters.e3)
end)

it('test 1', function()
  emitter:on('A',          counters'e0');
  emitter:on('A::*',       counters'e1');
  emitter:on('A::**',      counters'e2');
  emitter:on('A::**::B',   counters'e3');
  emitter:on('A::**::B::C',counters'e4');
  assert_true(emitter:emit('A::B::C'))

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
  assert_true(emitter:emit('A::G::B::C'))

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
  assert_true(emitter:emit('A::B::C'))

  assert_equal(0, counters.e0)
  assert_equal(0, counters.e1)
  assert_equal(1, counters.e2)
  assert_equal(0, counters.e3)
  assert_equal(1, counters.e4)
end)

it('test 4', function()
  emitter:on('**',         counters'e0');
  emitter:on('::**',       counters'e1');
  assert_true(emitter:emit('A'))

  assert_equal(1, counters.e0)
  assert_equal(0, counters.e1)
end)

it('test 4.1', function()
  emitter:on('**',         counters'e0');
  emitter:on('::**',       counters'e1');
  assert_true(emitter:emit(''))

  assert_equal(1, counters.e0)
  assert_equal(1, counters.e1)
end)

it('test 5', function()
  emitter:on('A::**',      counters'e0');
  emitter:on('A::*',       counters'e1');
  assert_true(emitter:emit('A'))

  assert_equal(1, counters.e0)
  assert_equal(0, counters.e1)
end)

it('test 6', function()
  emitter:on('A::**::C',   counters'e0');
  emitter:on('A::*',       counters'e1');
  assert_true(emitter:emit('A::B'))

  assert_equal(0, counters.e0)
  assert_equal(1, counters.e1)
end)

it('test 7', function()
  emitter:on('A::**::C',   counters'e0');
  emitter:on('A::*',       counters'e1');
  assert_true(emitter:emit('A::C'))

  assert_equal(1, counters.e0)
  assert_equal(1, counters.e1)
end)

it('test 8', function()
  emitter:on('A::**::C',   counters'e0');
  emitter:on('A::*',       counters'e1');
  assert_true(emitter:emit('A::B::C'))

  assert_equal(1, counters.e0)
  assert_equal(0, counters.e1)
end)

it('test 9', function()
  emitter:on('A::**',   counters'e0');

  assert_true(emitter:emit('A'))
  assert_equal(1, counters.e0)

  assert_true(emitter:emit('A::B'))
  assert_equal(2, counters.e0)

  assert_true(emitter:emit('A::*'))
  assert_equal(3, counters.e0)

  assert_false(emitter:emit('B'))
  assert_equal(3, counters.e0)

  assert_false(emitter:emit('B::A'))
  assert_equal(3, counters.e0)
end)

it('test 10', function()
  emitter:on  ('A::B',     counters'e0');
  emitter:once('A::**::B', counters'e1');

  assert_true(emitter:emit('A::B'))
  assert_equal(1, counters.e0)
  assert_equal(1, counters.e1)

  assert_true(emitter:emit('A::B'))
  assert_equal(2, counters.e0)
  assert_equal(1, counters.e1)
end)

it('test 11', function()
  emitter:on  ('A',     counters'e0');
  emitter:once('A::**', counters'e1');

  assert_true(emitter:emit('A'))
  assert_equal(1, counters.e0)
  assert_equal(1, counters.e1)

  assert_true(emitter:emit('A'))
  assert_equal(2, counters.e0)
  assert_equal(1, counters.e1)
end)

it('test 12', function()
  emitter:on('A::**::B', counters'e0');

  assert_true(emitter:emit('A::*::B'))
  assert_equal(1, counters.e0)

  assert_true(emitter:emit('A::*::*::B'))
  assert_equal(2, counters.e0)

  assert_true(emitter:emit('A::C::*::B'))
  assert_equal(3, counters.e0)

  assert_true(emitter:emit('A::*::B::B'))
  assert_equal(4, counters.e0)

  assert_true(emitter:emit('A::*::B::*'))
  assert_equal(5, counters.e0)
end)

it('test 13', function()
  emitter:on('A::**', counters'e0');

  assert_true(emitter:emit('A::A::A'))
  assert_equal(1, counters.e0)
end)

it('test 14', function()
  emitter:on('A::**',    counters'e0');
  emitter:on('A::A::**', counters'e1');

  assert_true(emitter:emit('A::A::A'))
  assert_equal(1, counters.e0)
  assert_equal(1, counters.e1)
end)

end

local _ENV = TEST_CASE'EventEmitter extend' if ENABLE then
local it = IT(_ENV or _M)

local exports = {'on','many','once','off','emit','onAny','manyAny','onceAny','offAny',
  'addListener', 'removeListener', 'removeAllListeners'}

local emitter, counters

function setup()
  counters = Counter()
end

function teardown()
  emitter, counters = nil
end

it("should extend class", function()
  local my_class = {}
  local t = EventEmitter.extend_class(my_class)
  assert_equal(my_class, t)
  for _, method in ipairs(exports) do
    assert_function(my_class[method], method)
    my_class[method] = nil
  end
  assert_nil(next(my_class))
end)

it("extend class should work", function()
  local CustomClass = EventEmitter.extend_class(ut.class())
  function CustomClass:__init()
    self._EventEmitter = EventEmitter.new{self=self}
    return self
  end

  emitter = CustomClass.new()

  emitter:on('A', counters'e0')
  assert_true(emitter:emit('A'))
  assert_equal(1, counters.e0)
end)

it("extend class should accept custom emitter name", function()
  local CustomClass = EventEmitter.extend(ut.class(), '_emitter')
  function CustomClass:__init()
    self._emitter = EventEmitter.new{self=self}
    return self
  end

  emitter = CustomClass.new()

  emitter:on('A', counters'e0')
  assert_true(emitter:emit('A'))
  assert_equal(1, counters.e0)
end)

it("extend class should accept function to get emitter", function()
  local CustomClass = ut.class() do
    function CustomClass:__init()
      self._private = {}
      self._private.emitter = EventEmitter.new{self=self}
      return self
    end

    function CustomClass:_emitter()
      return self._private.emitter
    end

    EventEmitter.extend(CustomClass, CustomClass._emitter)
  end

  emitter = CustomClass.new()

  emitter:on('A', counters'e0')
  assert_true(emitter:emit('A'))
  assert_equal(1, counters.e0)
end)

it("extend class should pass correct self", function()
  local CustomClass = EventEmitter.extend_class(ut.class())
  function CustomClass:__init()
    self._EventEmitter = EventEmitter.new{self=self}
    return self
  end

  emitter = CustomClass.new()

  emitter:on('A', function(self,event)
    assert_equal(emitter, self)
    assert_equal(event, 'A')
    counters'e0'()
  end)

  assert_true(emitter:emit('A'))

  assert_equal(1, counters.e0)
end)

it("should extend object", function()
  local object = ut.class{}.new()

  local t = EventEmitter.extend_object(object)
  assert_equal(object, t)

  for _, method in ipairs(exports) do
    assert_function(object[method], method)
  end
end)

it("extend object should work", function()
  emitter = EventEmitter.extend_object(ut.class{}.new())
  emitter:on('A', counters'e0')
  assert_true(emitter:emit('A'))
  assert_equal(1, counters.e0)
end)

it("extend object should pass correct self", function()
  emitter = EventEmitter.extend_object(ut.class{}.new())

  emitter:on('A', function(self,event)
    assert_equal(emitter, self)
    assert_equal(event, 'A')
    counters'e0'()
  end)

  assert_true(emitter:emit('A'))

  assert_equal(1, counters.e0)
end)

it("extend should raise error on unsupportde args", function()
  assert_error(function() EventEmitter.extend({}, {})    end)
  assert_error(function() EventEmitter.extend({}, true)  end)
  assert_error(function() EventEmitter.extend({}, false) end)
  assert_error(function() EventEmitter.extend()          end)
end)

end

local _ENV = TEST_CASE'EventEmitter remove listners' if ENABLE then
local it = IT(_ENV or _M)

local emitter, counters

function setup()
  counters = Counter()
end

function teardown()
  emitter, counters = nil
end

local events = {
  {'A',        'A'       };
  {'A::B::*',  'A::B::C' };
  {'A::B',     'A::*'    };
  {'A::B',     '*::B'    };
  {'A::*',     'A::*'    };
  {'A::*::C',  'A::B::C' };
  {'A::B::C',  'A::*::C' };
  {'A::**::C', 'A::B::C' };
  {'A::**',    'A::B::C' };
  {'A::**::B', 'A::B'    };
  {'A::**',    'A'       };
}

for _, event in ipairs(events) do

  it('should remove `' .. event[2] .. '` with mask `' .. event[1] ..  '` from tree emitter', function()
    emitter = EventEmitter.new{wildcard = true; delimiter = '::'}

    local mask, event = event[1],  event[2]
    local function listner()
      emitter:off(mask, listner)
      counters'e0'()
    end
    emitter:on(mask, listner)
    assert_pass(function() emitter:emit(event) end)
    assert_equal(1, counters.e0)
    assert_pass(function() emitter:emit(event) end)
    assert_equal(1, counters.e0)
  end)

  it('should call once `' .. event[2] .. '` with mask `' .. event[1] ..  '` from tree emitter', function()
    emitter = EventEmitter.new{wildcard = true; delimiter = '::'}

    local mask, event = event[1],  event[2]
    emitter:once(mask, counters'e0')
    assert_pass(function() emitter:emit(event) end)
    assert_equal(1, counters.e0)
    assert_pass(function() emitter:emit(event) end)
    assert_equal(1, counters.e0)
  end)

end

it('should remove any event', function()
  emitter = EventEmitter.new()

  local function listner()
    emitter:offAny(listner)
    counters'e0'()
  end
  emitter:onAny(listner)
  assert_pass(function() emitter:emit('A') end)
  assert_equal(1, counters.e0)
  assert_pass(function() emitter:emit('A') end)
  assert_equal(1, counters.e0)
end)

it('should call once any event', function()
  emitter = EventEmitter.new{wildcard = true; delimiter = '::'}

  emitter:onceAny(counters'e0')
  assert_pass(function() emitter:emit('A') end)
  assert_equal(1, counters.e0)
  assert_pass(function() emitter:emit('A') end)
  assert_equal(1, counters.e0)
end)

it('should off any event', function()
  emitter = EventEmitter.new{wildcard = true; delimiter = '::'}

  emitter:onAny(counters'e0')
  emitter:onAny(counters'e1')
  emitter:offAny(counters'e0')

  assert_pass(function() emitter:emit('A') end)
  assert_equal(0, counters.e0)
  assert_equal(1, counters.e1)
  assert_pass(function() emitter:emit('A') end)
  assert_equal(0, counters.e0)
  assert_equal(2, counters.e1)
end)

it('should off all any event', function()
  emitter = EventEmitter.new{wildcard = true; delimiter = '::'}

  emitter:onAny(counters'e0')
  emitter:onAny(counters'e1')
  emitter:offAny()

  assert_pass(function() emitter:emit('A') end)
  assert_equal(0, counters.e0)
  assert_equal(0, counters.e1)

  assert_pass(function() emitter:emit('A') end)
  assert_equal(0, counters.e0)
  assert_equal(0, counters.e1)
end)

it('should remove event from basic emitter', function()
  emitter = EventEmitter.new()

  local event = 'A'
  local function listner()
    emitter:off(event, listner)
    counters'e0'()
  end
  emitter:on(event, listner)
  assert_pass(function() emitter:emit(event) end)
  assert_equal(1, counters.e0)
  assert_pass(function() emitter:emit(event) end)
  assert_equal(1, counters.e0)
end)

it('should remove all events from basic emitter', function()
  emitter = EventEmitter.new()

  emitter:on   ('A', counters'e0')
  emitter:once ('B', counters'e1')
  emitter:onAny(     counters'e2')

  assert_equal(emitter, emitter:removeAllListeners())
  
  assert_false(emitter:emit('A'))
  assert_false(emitter:emit('B'))
  assert_false(emitter:emit('C'))

  assert_equal(0, counters.e0)
  assert_equal(0, counters.e1)
  assert_equal(0, counters.e2)
end)

it('should remove all listners from event from basic emitter', function()
  emitter = EventEmitter.new()

  emitter:on ('A', counters'e0')
  emitter:on ('A', counters'e1')
  emitter:on ('B', counters'e2')

  assert_equal(emitter, emitter:removeAllListeners('A'))
  
  assert_false(emitter:emit('A'))
  assert_true(emitter:emit('B'))

  assert_equal(0, counters.e0)
  assert_equal(0, counters.e1)
  assert_equal(1, counters.e2)
end)

it('should remove all events from tree emitter', function()
  emitter = EventEmitter.new{wildcard = true; delimiter = '::'}

  emitter:on   ('A', counters'e0')
  emitter:once ('B', counters'e1')
  emitter:onAny(     counters'e2')

  assert_equal(emitter, emitter:removeAllListeners())
  
  assert_false(emitter:emit('A'))
  assert_false(emitter:emit('B'))
  assert_false(emitter:emit('C'))

  assert_equal(0, counters.e0)
  assert_equal(0, counters.e1)
  assert_equal(0, counters.e2)
end)

it('should remove all listners from event from tree emitter', function()
  emitter = EventEmitter.new{wildcard = true; delimiter = '::'}

  emitter:on ('A',    counters'e0')
  emitter:on ('A',    counters'e1')
  emitter:on ('A::*', counters'e2')

  assert_equal(emitter, emitter:removeAllListeners('A'))
  
  assert_false(emitter:emit('A'))
  assert_true(emitter:emit('A::B'))

  assert_equal(0, counters.e0)
  assert_equal(0, counters.e1)
  assert_equal(1, counters.e2)
end)

it('should remove all listners from event with mask from tree emitter', function()
  emitter = EventEmitter.new{wildcard = true; delimiter = '::'}

  emitter:on ('A',    counters'e0')
  emitter:on ('A',    counters'e1')
  emitter:on ('A::*', counters'e2')
  emitter:on ('A::B', counters'e3')

  assert_equal(emitter, emitter:removeAllListeners('A::*'))
  
  assert_true(emitter:emit('A'))
  assert_true(emitter:emit('A::B'))

  assert_equal(1, counters.e0)
  assert_equal(1, counters.e1)
  assert_equal(0, counters.e2)
  assert_equal(1, counters.e3)
end)

end

RUN()
