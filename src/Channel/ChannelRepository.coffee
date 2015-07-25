###
Manages channels and provides an interface to multiple channels for a client.
###
module.exports = class ChannelRepository

  constructor: () ->
    @channels = {}


  # Removes the given client from all channels
  removeClient: (client) ->
    for name, channel of @channels
      channel.removeSubscription(client)


  # Returns a channel by name
  getChannel: (name) ->
    return @channels[name]


  # Creates a new channel by name if it doesn't already exist.
  createChannel: (name) ->
    if name not of @channels
      @channels[name] = new Channel(name)

    return @channels[name]
