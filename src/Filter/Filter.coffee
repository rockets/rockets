###
Base filter, used to determine if a subscription should receive a model.
###
module.exports = class Filter

  # Filter value types
  @BOOLEAN   = 'boolean'
  @STRING    = 'string'
  @STRING_I  = 'string_i'
  @REGEX     = 'regex'

  constructor: (rules) ->
    if typeof rules is 'object' then @parseRules(rules, @schema())


  # Parses all given rules into consistent formats. This also removes
  # any unsupported rules, and prepares complex ones for later use.
  parseRules: (rules, schema) ->
    @rules = {}

    for key of rules
      if key of schema
        @rules[key] =
          pass: @parse(rules[key], schema[key]),
          type: schema[key]


  # Parses a single rule against an expected type.
  parse: (rule, type) ->

    # Convert every rule into an array for consistency
    rule = [].concat(rule)

    switch type
      when Filter.STRING    then return rule.map (x) -> "#{x}"
      when Filter.STRING_I  then return rule.map (x) -> "#{x}".toLowerCase()
      when Filter.BOOLEAN   then return rule.map (x) -> !! x
      when Filter.REGEX
        try
          return new RegExp((rule.map (x) -> "(?:#{x})").join('|'), 'i')

        # This indicates that a regex rule was provided but wasn't valid,
        # which should fail validation.
        return false


  # Passes if the rule is empty or contains the value
  check: (rule, value) ->
    type = rule.type
    pass = rule.pass

    # Rules that failed to parse should fail validation.
    if not pass then return false

    # Handle the regex test first because it doesn't operate on an array.
    if type is Filter.REGEX then return pass.test(value)

    # Convert the value to lowercase if the rule is case insensitive.
    if type is Filter.STRING_I then value = value.toLowerCase()

    # Pass if either the rule is empty or the value is in the rule.
    return pass.length is 0 or value in pass

  # Validates a model against this rule, ie. determines if the model should be
  # sent to the client that owns the subscription that contains this rule.
  validate: (model) ->
    if @rules
      for name, rule of @rules
        if not @[name](model, rule) then return false

    return true
