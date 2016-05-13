# lua-EventEmitter
[![Build Status](https://travis-ci.org/moteus/lua-EventEmitter.svg?branch=master)](https://travis-ci.org/moteus/lua-EventEmitter)
[![Coverage Status](https://coveralls.io/repos/github/moteus/lua-EventEmitter/badge.svg?branch=master)](https://coveralls.io/github/moteus/lua-EventEmitter?branch=master)
[![License](http://img.shields.io/badge/License-MIT-brightgreen.svg)](LICENSE)

Implementation of EventEmitter for Lua.

### Extend 30log class

```Lua
local EE    = require "EventEmitter"
local class = require "30log"

-- Create wrapper for EventEmitter
local EventEmitter = class('EventEmitter') do

function EventEmitter:init()
  -- object have to have `_EventEmitter` property
  self._EventEmitter = EE.EventEmitter.new{self = self}
end

EE.extend_class(EventEmitter)

end

local Window = EventEmitter:extend('Window')

local window = Window:new()

window:on('resize', function(self, event, w, h)
  print(self, ("Resized %dx%d"):format(w, h))
end)

window:emit('resize', 125, 250)
```

### Wrap some table with emitter
```Lua
local EventEmitter = require "EventEmitter"

local server = {}

EventEmitter.extend_object(server)

server:on('accept', function() ... end)

server:emit('accept', host, port)
```

