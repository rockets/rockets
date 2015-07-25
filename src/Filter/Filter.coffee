###
Base filter, used to determine if a subscription should receive a model.
###
module.exports = class Filter

  # Filter value types
  @BOOLEAN = 'boolean'
  @STRING  = 'string'
  @REGEX   = 'regex'

  constructor: (values) ->
    if typeof values is 'object' then @parseValues(values, @schema())


  # Parses all given filter values into consistent formats. This also removes
  # any unsupported filters, and prepares complex ones for later use.
  parseValues: (values, schema) ->
    @filters = {}

    for key of values
      if key of schema
        value = @parse(values[key], schema[key])

        # Only set the filter if it resolved to something useful
        if value? then @filters[key] = value


  # Parses a single value against an expected type.
  parse: (value, type) ->

    # Convert every value into an array for consistency
    value = [].concat(value)

    switch type
      when Filter.STRING  then return value.map (x) -> "#{x}"
      when Filter.BOOLEAN then return value.map (x) -> !! x
      when Filter.REGEX
        try
          return new RegExp((value.map (x) -> "(?:#{x})").join('|'), 'i')

        # This indicates that a filter was provided but wasn't valid,
        # which should fail validation.
        return false


  # Passes if the filter is empty or contains the value
  check: (filter, value) ->
    return filter.length is 0 or value in filter


  # Checks if a model's subreddit matches any of the values in the filter.
  subreddit: (model, filter) ->
    return @check(filter, model.data.subreddit)


  # Checks if a model's user/author matches any of the values in the filter.
  author: (model, filter) ->
    return @check(filter, model.data.author)


  # Validates a model against this filter, ie. determines if the model should be
  # send to the client that owns the subscription that contains this filter.
  validate: (model) ->
    if @filters
      for name, filter of @filters
        if not @[name](model, filter) then return false

    return true
