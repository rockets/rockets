###
A container for pairing a client to a filter, managed by a channel.
###
module.exports = class Subscription

  constructor: (@client, @filters) ->

  # Determines whether a given model matches this subscription.
  match: (model) ->

    # Match all if no filters were provided.
    if not @filters
      return true

    # Inclusion filters SHOULD validate if provided.
    if @filters.include and not @filters.include.validate(model)
      return false

    # Exclusion filters SHOULD NOT validate if provided.
    if @filters.exclude and @filters.exclude.validate(model)
      return false

    # All filters passed.
    return true
