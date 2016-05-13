local EventEmitter = require "EventEmitter"

local server = EventEmitter.new()

server:on('say', function(self, event, word)
  print(event, ':', word)
end)

server:emit('say', 'hello world')