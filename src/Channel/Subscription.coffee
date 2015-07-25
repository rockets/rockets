###
A container for pairing a client to a filter, managed by a channel.
###
module.exports = class Subscription

  constructor: (@client, @filter) ->

  # Determines whether a given model matches this subscription.
  match: (model) ->
    return not @filter or @filter.validate(model)
