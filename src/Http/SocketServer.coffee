###
Socket server, responsible for:
  - Keeping track of client channels using a ChannelRepository
  - Listening for new connections
  - Listening for dropped connections
###
module.exports = class SocketServer

  @MAX_MESSAGE_SIZE = 1000 * 1000  # 1Mb

  constructor: () ->
    @channels = new ChannelRepository()


  # Starts the server and listens for new connections
  listen: (options) ->
    @server = new ws.Server options

    # Called when a new client has connected.
    @server.on 'connection', @onConnect.bind(@)


  # Returns this server's channels.
  getChannels: () ->
    return @channels


  # Called when a new client has connected.
  onConnect: (socket) ->
    client = new SocketClient(socket)

    log.info 'client.connect',
      client: client.id

    # Called when an incoming message is received
    socket.on 'message', (message) =>
      @onMessage(message, client)

    # Called when the connection to a client is lost.
    socket.on 'close', () =>
      @onDisconnect(client)

    # Called when an error occurs on the socket.
    socket.on 'error', (err) ->
      log.error err or 'Unknown socket error'


  # Called when the connection to a client is lost.
  onDisconnect: (client) ->
    @channels.removeClient(client)
    log.info 'client.disconnect',
      client: client.id,


  # Called when an incoming message is received.
  onMessage: (message, client) ->
    if (data = @parseMessage(message, client)) then @handleData(data, client)


  # Determines and returns and appropriate filter for the given data.
  getFilters: (data, client) ->

    # Don't break BC
    if data.filters
      data.include = data.filters

    switch data.channel
      when Channel.POSTS    then filter = PostFilter
      when Channel.COMMENTS then filter = CommentFilter
      else
        return

    # Check that filters were actually provided, where empty is false.
    include = if Object.keys(data.include or {}).length then data.include
    exclude = if Object.keys(data.exclude or {}).length then data.exclude

    return {
      include: if include then new filter(include) else undefined
      exclude: if exclude then new filter(exclude) else undefined
    }


  # Log error and forward to client
  clientError: (client, error) ->

    # Log client error.
    log.error 'client.error',
      client: client.id
      error: error

    # Send error to client
    client.send
      error: error


  # Determines and returns a channel instance for the given data.
  # Sends an error to the client if the channel is not supported.
  getChannel: (data, client) ->
    if data.channel in [Channel.POSTS, Channel.COMMENTS]
      return @channels.createChannel(data.channel)

    # Send an error message to the client.
    @clientError client,
      message: 'Unsupported channel'
      options: [Channel.POSTS, Channel.COMMENTS]


  # Guards against massive JSON messages.
  validMessageSize: (message) ->
    return Buffer.byteLength(message, 'utf8') < SocketServer.MAX_MESSAGE_SIZE


  parseJson: (json, client) ->
    try
      return JSON.parse(json)

    catch e
      @clientError client,
        message: "Could not parse subscription: #{e.message}"


  # Attempts to parse an incoming message.
  # Sends an error to the client if the message could not be parsed.
  parseMessage: (message, client) ->

    # Log the raw subscription.
    log.info 'subscription.raw',
      data: message
      client: client.id

    if @validMessageSize(message)
      return @parseJson message, client

    # Send an error message to the client.
    @clientError client,
      message: 'JSON message too large!'


  # Handles the data of a parsed message.
  # Creates a subscription if the data produces a valid channel.
  handleData: (data, client) ->

    log.info 'subscription',
      data: data
      client: client.id

    channel = @getChannel(data, client)
    filters = @getFilters(data, client)

    if channel then channel.addSubscription(new Subscription(client, filters))
