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
      event: 'connect',
      client: client.id,
    }

    # Called when an incoming message is received
    socket.on 'message', (message) =>
      @onMessage(message, client)

    # Called when the connection to a client is lost.
    socket.on 'close', () =>
      @onDisconnect(client)


  # Called when the connection to a client is lost.
  onDisconnect: (client) ->
    @channels.removeClient(client)

    log.info {
      event: 'disconnect',
      client: client.id,
    }


  # Attempts to parse a message to determine the channel and channel filters.
  parseMessage: (message, callback) ->
    try
      data = JSON.parse(message)

      switch data.channel

        when Channel.POSTS
          callback
            channel: @channels.createChannel(Channel.POSTS)
            filters: new PostFilter(data.filters) if data.filters

        when Channel.COMMENTS
          callback
            channel: @channels.createChannel(Channel.COMMENTS)
            filters: new CommentFilter(data.filters) if data.filters


  # Called when an incoming message is received.
  onMessage: (message, client) ->

    log.info {
      event: 'message',
      message: message,
      client: client.id,
    }

    @parseMessage message, (data) ->
      data.channel.addSubscription(new Subscription(client, data.filters))
