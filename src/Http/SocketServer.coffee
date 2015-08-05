###
Socket server, responsible for:
  - Keeping track of client channels using a ChannelRepository
  - Listening for new connections
  - Listening for dropped connections
###
module.exports = class SocketServer

  constructor: () ->
    @channels = new ChannelRepository()


  # Starts the server and listens for new connections
  listen: (options) ->
    @server = new ws.Server options

    # Called when a new client has connected.
    @server.on 'connection', (socket) =>
      @onConnect(socket)


  # Returns this server's channels.
  getChannels: () ->
    return @channels


  # Called when a new client has connected.
  onConnect: (socket) ->
    client = new SocketClient(socket)

    log.info {
      event: 'client.connect',
      client: client.id,
    }

    # Called when an incoming message is received
    socket.on 'message', (message) =>
      @onMessage(message, client)

    # Called when the connection to a client is lost.
    socket.on 'close', () =>
      @onDisconnect(client)

    socket.on 'error', Log.errorHandler


  # Called when the connection to a client is lost.
  onDisconnect: (client) ->
    @channels.removeClient(client)

    log.info {
      event: 'client.disconnect',
      client: client.id,
    }


  # Called when an incoming message is received.
  onMessage: (message, client) ->

    log.info {
      event: 'client.message',
      message: message,
      client: client.id,
    }

    # Attempt to parse the incoming message
    if data = @parseMessage(message, client) then @handleData(data, client)


  # Determines and returns and appropriate filter for the given data.
  getFilters: (data, client) ->
    switch data.channel
      when Channel.POSTS    then return new PostFilter(data.filters)
      when Channel.COMMENTS then return new CommentFilter(data.filters)


  # Logs a client error then sends it to the client.
  clientError: (client, error) ->
    log.error   {error}
    client.send {error}

  # Determines and returns a channel instance for the given data.
  # Sends an error to the client if the channel is not supported.
  getChannel: (data, client) ->
    if data.channel in [Channel.POSTS, Channel.COMMENTS]
      return @channels.createChannel(data.channel)

    error = {
      message: 'Unsupported channel'
    }

    log.error   {error}
    client.send {error}


  # Attempts to parse an incoming message.
  # Sends an error to the client if the message could not be parsed.
  parseMessage: (message, client) ->
    try
      return JSON.parse(message)
    catch err

      error = {
        message: err.message,
      }

      log.error   {error}
      client.send {error}


  # Handles the data of a parsed message.
  # Creates a subscription if the data produces a valid channel.
  handleData: (data, client) ->

    log.info {
      event: 'subscription',
      data: data,
      client: client.id,
    }

    channel = @getChannel(data, client)
    filters = @getFilters(data, client)

    if channel then channel.addSubscription(new Subscription(client, filters))
