local EE    = require "EventEmitter"
local class = require "30log"

-- Create wrapper for EventEmitter
local EventEmitter = EE.extend(class('EventEmitter')) do

function EventEmitter:init()
  -- object by default should have `_EventEmitter` property
  self._EventEmitter = EE.EventEmitter.new{self = self}
end

end

local Window = EventEmitter:extend('Window')

local window = Window:new()

window:on('resize', function(self, event, w, h)
  print(self, ("Resized %dx%d"):format(w, h))
end)

window:emit('resize', 125, 250)

