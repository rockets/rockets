###
Subscription channel, responsible for:
  - Storing subscriptions
  - Storing a link between a subscription and its client, by id.
###
module.exports = class Channel

  @COMMENTS = 'comments'
  @POSTS    = 'posts'

  constructor: (@name) ->
    @subscriptions = {}


  # Adds a subscription to this channel.
  addSubscription: (subscription) ->
    @subscriptions[subscription.client.id] = subscription


  # Removes a client's subscription from this channel.
  removeSubscription: (client) ->
    try
      delete @subscriptions[client.id]

    catch exception
      log.error {
        message: 'Could not delete subscription',
        exception: exception,
      }
