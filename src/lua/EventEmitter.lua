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

local EE = {
  _NAME      = "EventEmitter";
  _VERSION   = "0.1.1";
  _COPYRIGHT = "Copyright (C) 2016 Alexey Melnichuk";
  _LICENSE   = "MIT";
}

local ut = require "EventEmitter.utils"

local function callable(f)
  return type(f) == 'function'
end

local function empty(t)
  return (not t) or (nil == next(t))
end

local BasicEventEmitter = ut.class() do

local ANY_EVENT = {}

BasicEventEmitter.ANY = ANY_EVENT

function BasicEventEmitter:__init()
  -- map of array of listeners
  self._handlers = {}
  -- map to convert user's listener to internal wrapper
  self._once     = {}

  return self
end

function BasicEventEmitter:on(event, handler)
  local list = self._handlers[event] or {}

  for i = 1, #list do
    if list[i] == handler then
      return self
    end
  end

  list[#list + 1] = handler
  self._handlers[event] = list

  return self
end

function BasicEventEmitter:many(event, ttl, handler)
  self:off(event, handler)

  local function listener(...)
    ttl = ttl - 1
    if ttl == 0 then self:off(event, handler) end
    handler(...)
  end

  self:on(event, listener)
  self._once[handler] = listener

  return self
end

function BasicEventEmitter:once(event, handler)
  return self:many(event, 1, handler)
end

function BasicEventEmitter:off(event, handler)
  local list = self._handlers[event]

  if not list then return self end

  if handler then

    local listener = self._once[handler] or handler
    self._once[handler] = nil

    for i = 1, #list do
      if list[i] == listener then
        table.remove(list, i)
        break
      end
    end

    if #list == 0 then self._handlers[event] = nil end

  else

    for handler, listener in pairs(self._once) do
      for i = 1, #list do
        if list[i] == listener then
          self._once[handler] = nil
          break
        end
      end
    end

    self._handlers[event] = nil 

  end

  return self
end

function BasicEventEmitter:onAny(handler)
  return self:on(ANY_EVENT, handler)
end

function BasicEventEmitter:manyAny(ttl, handler)
  return self:many(ANY_EVENT, ttl, handler)
end

function BasicEventEmitter:onceAny(handler)
  return self:once(ANY_EVENT, handler)
end

function BasicEventEmitter:offAny(handler)
  return self:off(ANY_EVENT, handler)
end

function BasicEventEmitter:_emit_impl(call_any, event, ...)
  local ret = false

  if call_any and ANY_EVENT ~= event then
    ret = self:_emit_impl(false, ANY_EVENT, ...) or ret
  end

  local list = self._handlers[event]

  if list then
    for i = #list, 1, -1 do
      if list[i] then
        -- we need this check because cb could remove some listeners
        list[i](...)
        ret = true
      end
    end
  end

  return ret
end

function BasicEventEmitter:emit(event, ...)
  return self:_emit_impl(true, event, ...)
end

function BasicEventEmitter:_emit_all(...)
  -- we have to copy because cb can remove/add some events
  -- and we do not need call new one or removed one
  local names = {}
  for name in pairs(self._handlers) do
    names[#names+1] = name
  end

  local ret = false
  for i = 1, #names do
    ret = self:_emit_impl(false, names[i], ...) or ret
  end

  return ret
end

function BasicEventEmitter:_empty()
  return nil == next(self._handlers)
end

function BasicEventEmitter:removeAllListeners(eventName)
  if not eventName then
    self._handlers = {}
    self._once     = {}
  else
    self:off(eventName)
  end

  return self
end

end

local TreeEventEmitter = ut.class() do

local ANY = BasicEventEmitter.ANY
local AN2 = {}

-- each `node` has two parts
--   array part has:
--     [1] - BasicEventEmitter
--   hash part is map
--     [sub event] => node
--
-- 'A'=>e0
-- 'A::*'=>e1
-- 'A::B'=>e2
-- 'A::*::B'=>e5
-- 'A::B::C'=>e3
-- 'A::B::*'=>e4
-- 'A::**'=>e6
-- 'A::**::B'=>e7
-- node{
--   1 = EE{
--     A => E0
--   }
--   A = {
--     1 = EE{
--       * => e1
--      ** => e6
--       B => e2
--     }
--     B = node{
--       1 = EE{
--         * => e4
--         C => e3
--       }
--     }
--     * = node{
--       1 = EE{
--         B => e5
--       }
--     }
--    ** = node{
--       1 = EE{
--         B => e5
--       }
--     }
--   }
-- }

function TreeEventEmitter:__init(sep, wildcard)
  self._sep = sep or '.'
  self._wld = wildcard or '*'
  self._wl2 = self._wld .. self._wld
  self._any = BasicEventEmitter.new()

  self._tree  = {}
  return self
end

local function find_emitter(self, event, create, node, cb, ...)
  local name, tail = ut.split_first(event, self._sep, true)

  if not tail then
    event = (event == self._wld) and ANY or (event == self._wl2) and AN2 or event
    local emitter = node[1]
    if not emitter then
      if not create then return false end
      emitter = BasicEventEmitter.new()
      node[1] = emitter
    end
    cb(emitter, event, ...)
    -- remove empty emitter. We really need check only on `off` event
    if (not create) and emitter:_empty() then node[1] = nil end
    return true
  end

  -- If we have tail and this tail is not wildcard then we
  -- need continue search in subtree
  local tree = node[name]
  if not tree then
    -- If we just whant remove event wich does not exists we do not need 
    -- create subtree, we just can stop search
    if not create then return end
    tree = {}
    node[name] = tree
  end

  local ret = find_emitter(self, tail, create, tree, cb, ...)
  if (not create) and empty(tree) then
    node[name] = nil
  end

  return ret
end

function TreeEventEmitter:many(event, ...)
  find_emitter(self, event, true, self._tree, BasicEventEmitter.many, ...)
  return self
end

function TreeEventEmitter:once(event, ...)
  find_emitter(self, event, true, self._tree, BasicEventEmitter.once, ...)
  return self
end

function TreeEventEmitter:on(event, ...)
  find_emitter(self, event, true, self._tree, BasicEventEmitter.on, ...)
  return self
end

function TreeEventEmitter:off(event, ...)
  find_emitter(self, event, false, self._tree, BasicEventEmitter.off, ...)
  return self
end

-- wld true if `node` is match to `**`
local function do_emit(self, wld, event, node, ...)
  local ret = false

  if not node then return ret end

  local name, tail = ut.split_first(event, self._sep, true)

  if not tail then
    -- match mask to event
    local emitter = node[1]
    if emitter then
      if event == self._wld then
        ret = emitter:_emit_all() or ret
      else
        ret = emitter:_emit_impl(false, AN2, ...) or ret
        ret = emitter:emit(event, ...) or ret
      end
      if emitter:_empty() then
        node[1] = nil
      end
    end

    -- match mask is 'A::**::B' and event is 'A::B'
    emitter = node[self._wl2] and node[self._wl2][1]
    if emitter then
      if event == self._wld then
        ret = emitter:_emit_all() or ret
      else
        ret = emitter:emit(event, ...) or ret
      end
      if node[self._wl2] then
        if emitter:_empty() then
          node[self._wl2][1] = nil
        end
        if empty(node[self._wl2]) then
          node[self._wl2] = nil
        end
      end
    end

    -- match mask 'A::**' to event 'A'
    emitter = node[name] and node[name][1]
    if emitter then
      ret = emitter:_emit_impl(false, AN2, ...) or ret
      if node[name] then
        if emitter:_empty() then
          node[name][1] = nil
        end
        if empty(node[name]) then
          node[name] = nil
        end
      end
    end

    return ret
  end

  -- if we have mask like `A::**` and emit event say `A::B::C` then
  -- we have call this listener for node `A`
  if node[1] then
    ret = node[1]:_emit_impl(false, AN2, ...) or ret
    if node[1] and node[1]:_empty() then
      node[1] = nil
    end
  end

  -- wld = true if current node has mask == '**'
  if wld then
    -- we should keep looking tail in current node
    ret = do_emit(self, true, tail, node, ...) or ret
  elseif node[self._wl2] then
    -- we should start looking event in wildcard node
    -- e.g. we have mask='A::**::B' and event='A::B'
    -- so here name = 'A', tail = 'B' so we have to use `event`
    ret = do_emit(self, true, event, node[self._wl2], ...) or ret
    if empty(node[self._wl2]) then
      node[self._wl2] = nil
    end
  end

  -- here we handle wildcard in mask like `A::*::B`
  if node[self._wld] then
    ret = do_emit(self, false, tail, node[self._wld], ...) or ret
    if empty(node[self._wld]) then
      node[self._wld] = nil
    end
  end

  -- check if event has wildcard like `A::*`
  if name == self._wld then
    for k, v in pairs(node) do if (k ~= 1) and (k ~= self._wld) and (k ~= self._wl2) then
      ret = do_emit(self, false, tail, v, ...) or ret
      if empty(v) then
        node[k] = nil
      end
    end end
  else
    if node[name] then
      ret = do_emit(self, false, tail, node[name], ...) or ret
      -- listener can remove self from EE so there may be no `node[name]` any more
      if empty(node[name]) then
        node[name] = nil
      end
    end
  end

  return ret
end

function TreeEventEmitter:emit(event, ...)
  local ret = self._any:emit(ANY, ...)
  return do_emit(self, false, event, self._tree, ...) or ret
end

function TreeEventEmitter:onAny(handler)
  self._any:onAny(handler)
  return self
end

function TreeEventEmitter:manyAny(ttl, handler)
  self._any:manyAny(ttl, handler)
  return self
end

function TreeEventEmitter:onceAny(handler)
  self._any:onceAny(handler)
  return self
end

function TreeEventEmitter:offAny(handler)
  self._any:offAny(handler)
  return self
end

function TreeEventEmitter:removeAllListeners(eventName)
  if not eventName then
    self._any:removeAllListeners()
    self._tree = {}
  else
    self:off(eventName)
  end

  return self
end

end

do -- Debug code

-- local C = {}
-- local c = function(str) C[str]= C[str] or function() print(str) end; return C[str] end
-- local server = TreeEventEmitter.new('::')
-- server:on('A',           c'e0');
-- server:on('A::*',        c'e1');
-- server:on('A::**',       c'e2');
-- server:on('A::**::C',    c'e3');
-- server:on('A::**::B::C', c'e4');
-- server:once('A::**::B::C', c'e4');

-- server:emit('A::B')
-- server:emit('A::*')
-- server:emit('A::B::C')

-- local function h() server:off('A::**::B', h) end
-- server:on('A::**::B', h);
-- server:emit('A::B')

end

local EventEmitter = ut.class() do

function EventEmitter:__init(opt)
  if opt and opt.wildcard then
    self._EventEmitter = TreeEventEmitter.new(opt.delimiter)
  else
    self._EventEmitter = BasicEventEmitter.new()
  end
  self._EventEmitter_self = opt and opt.self or self

  return self
end

function EventEmitter:on(event, listener)
  assert(event, 'event expected')
  assert(callable(listener), 'function expected')

  self._EventEmitter:on(event, listener)
  return self
end

function EventEmitter:many(event, ttl, listener)
  assert(event, 'event expected')
  assert(type(ttl) == 'number', 'number required')
  assert(callable(listener), 'function expected')

  self._EventEmitter:many(event, ttl, listener)
  return self
end

function EventEmitter:once(event, listener)
  assert(event, 'event expected')
  assert(callable(listener), 'function expected')

  self._EventEmitter:once(event, listener)
  return self
end

function EventEmitter:off(event, listener)
  assert(event, 'event expected')
  assert((listener == nil) or callable(listener), 'function expected')

  self._EventEmitter:off(event, listener)
  return self
end

function EventEmitter:emit(event, ...)
  assert(event, 'event expected')

  return self._EventEmitter:emit(event, self._EventEmitter_self, event, ...)
end

function EventEmitter:onAny(listener)
  assert(callable(listener), 'function expected')

  self._EventEmitter:onAny(listener)
  return self
end

function EventEmitter:manyAny(ttl, listener)
  assert(type(ttl) == 'number', 'number required')
  assert(callable(listener), 'function expected')

  self._EventEmitter:manyAny(ttl, listener)
  return self
end

function EventEmitter:onceAny(listener)
  assert(callable(listener), 'function expected')

  self._EventEmitter:onceAny(listener)
  return self
end

function EventEmitter:offAny(listener)
  assert((listener == nil) or callable(listener), 'function expected')

  self._EventEmitter:offAny(listener)
  return self
end

function EventEmitter:removeAllListeners(eventName)
  self._EventEmitter:removeAllListeners(eventName)
  return self
end

-- aliases

EventEmitter.addListener    = EventEmitter.on

EventEmitter.removeListener = EventEmitter.off

end

local extend, wrap do

local exports = {'on', 'many', 'once', 'off', 'emit', 'onAny', 'manyAny', 'onceAny', 'offAny',
  'addListener', 'removeListener', 'removeAllListeners'
}

extend = function(class, getter)
  getter = (getter == nil) and '_EventEmitter' or getter

  if type(getter) == 'string' then
    for _, method in ipairs(exports) do
      class[method] = function(self, ...)
        local emitter = self[getter]
        return emitter[method](emitter, ...)
      end
    end

  elseif type(getter) == 'function' then
    for _, method in ipairs(exports) do
      class[method] = function(self, ...)
        local emitter = getter(self)
        return emitter[method](emitter, ...)
      end
    end


  elseif getmetatable(getter) == EventEmitter then
    local emitter = getter
    for _, method in ipairs(exports) do
      class[method] = function(self, ...)
        return emitter[method](emitter, ...)
      end
    end

  else error('Unsupported Emitter get argument: ' .. type(getter)) end

  return class
end

wrap = function(object, emitter)
  emitter = emitter or EventEmitter.new{self = object}
  return extend(object, emitter)
end

end

return ut.clone(EE, {
  EventEmitter  = EventEmitter,
  new           = EventEmitter.new,
  extend        = extend,
  extend_class  = extend,
  extend_object = wrap,
})
