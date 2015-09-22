###
Worker process, responsible for:
  - Creating and handling a socket server
  - Emitting models to subscribed connections
###
module.exports = class Worker

  constructor: () ->
    @server = new SocketServer()
    @run()

  # Starts the server and handling of incoming messages from the master process.
  run: () ->
    @server.listen(port: process.env.PORT)
    # process.on 'message', @onMessage.bind(@)
    # process.on 'error', @onError.bind(@)


  # Called when an error occurred.
  # See https://nodejs.org/api/child_process.html#child_process_event_error
  # onError: (err) ->
    # log.error err


  # Sends a task to the emit queue which will send the model to the client.
  # enqueue: (client, model) ->
  #   @queue.push {client, model}


  # Loops through all subscriptions in a given channel, checking if the
  # subscription should receive the given model, in which case enqueues a task
  # to send the model to the client that created the subscription.
  sendToChannel: (channel, model) ->
    for clientId, subscription of channel.subscriptions or []
      if subscription.match model
        subscription.client.send(model)
        # @enqueue subscription.client, model

  # Handles a message received from the model queue, which contains a 'channel'
  # and a 'model'. Sends the model to all matching subscriptions in the channel.
  onMessage: (message) ->
    channel = @server.getChannels().getChannel(message.channel)

    if channel
      @sendToChannel channel, message.model
