###
Wraps around a socket connection, providing an ID to identify it by.
###
module.exports = class SocketClient

  constructor: (@socket) ->
    @id = uuid.v4() # Incremental ID's would get mixed up across workers.


  # Sends data to this client via it's socket connection.
  # Will be encoded as JSON if not already a string.
  send: (data, done) ->
    if typeof data isnt 'string' then data = JSON.stringify(data)

    @socket.send data, (error) ->
      if error then log.error error
      done?()
