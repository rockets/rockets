###
Base filter, used to determine if a subscription should receive a model.
###
module.exports = class Filter

  # Filter value types
  @BOOLEAN = 'boolean'
  @STRING  = 'string'
  @REGEX   = 'regex'

  constructor: (rules) ->
    if typeof rules is 'object' then @parseRules(rules, @schema())


  # Parses all given rules into consistent formats. This also removes
  # any unsupported rules, and prepares complex ones for later use.
  parseRules: (rules, schema) ->
    @rules = {}

    for key of rules
      if key of schema
        rule = @parse(rules[key], schema[key])

        # Only set the filter if it resolved to something useful
        if rule? then @rules[key] = rule


  # Parses a single rule against an expected type.
  parse: (rule, type) ->

    # Convert every rule into an array for consistency
    rule = [].concat(rule)

    switch type
      when Filter.STRING  then return rule.map (x) -> "#{x}"
      when Filter.BOOLEAN then return rule.map (x) -> !! x
      when Filter.REGEX
        try
          return new RegExp((rule.map (x) -> "(?:#{x})").join('|'), 'i')

        # This indicates that a "contains" rule was provided but wasn't valid,
        # which should fail validation.
        return false


  # Passes if the rule is empty or contains the value
  check: (rule, value) ->
    return rule.length is 0 or value in rule


  # Checks if a model's subreddit matches any of the values in the rule.
  subreddit: (model, rule) ->
    return @check(rule, model.data.subreddit)


  # Checks if a model's user/author matches any of the values in the rule.
  author: (model, rule) ->
    return @check(rule, model.data.author)


  # Validates a model against this rule, ie. determines if the model should be
  # send to the client that owns the subscription that contains this rule.
  validate: (model) ->
    if @rules
      for name, rule of @rules
        if not @[name](model, rule) then return false

    return true
