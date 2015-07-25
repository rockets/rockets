###
Worker process, responsible for:
  - Creating and handling a socket server
  - Emitting models to subscribed connections
###
module.exports = class Worker

  constructor: () ->
    @server = new SocketServer()
    @queue  = new EmitQueue()

    @run()

  # Starts the server and handling of incoming messages from the master process.
  run: () ->
    @server.listen(port: process.env.PORT)
    process.on('message', @onMessage.bind(@))
    process.on('error', @onError.bind(@))


  # Called when an error occurred.
  # See https://nodejs.org/api/child_process.html#child_process_event_error
  onError: (err) ->
    log.error err


  # Handles a message received from master
  onMessage: (message) ->
    channel = @server.getChannels().getChannel(message.channel)
    payload = message.model

    async.nextTick () =>
      for clientId, subscription of channel?.subscriptions
        if subscription.match(payload)
          client = subscription.client
          @queue.push {client, payload}
