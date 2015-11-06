###
Wraps around a socket connection, providing an ID to identify it by.
###
module.exports = class SocketClient

  constructor: (@socket) ->
    @id = uuid.v4()


  # Sends data to this client via it's socket connection.
  # Will be encoded as JSON if not already a string.
  send: (data, done) ->

    # Encode to JSON if not already a string
    if typeof data isnt 'string' then data = JSON.stringify(data)

    # Only send if the socket connection is still open
    if @socket?.readyState is ws.OPEN
      @socket.send data, (err) ->
        if err
          log.error {
            message: 'Socket send error?'
            error: err
          }

      done()

    else
      process.nextTick(done)
