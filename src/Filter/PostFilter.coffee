###
Filter for a post model.
###
module.exports = class PostFilter extends Filter

  # These are the supported keys and expected types for this filter.
  schema: () ->
    contains:     Filter.REGEX
    author:       Filter.STRING
    subreddit:    Filter.STRING
    domain:       Filter.STRING
    url:          Filter.STRING
    nsfw:         Filter.BOOLEAN


  # Checks if a post contains any of the patterns in the rule.
  contains: (post, regex) ->
    return regex and regex.test("#{post.data.title} #{post.data.selftext}")


  # Checks if a post's domain matches any of the domains in the rule.
  domain: (post, rule) ->
    return @check(rule, post.data.domain)


  # Checks if a post's URL matches any of the URL's in the rule.
  url: (post, rule) ->
    return @check(rule, post.data.url)


  # Checks if the rule contains whether a post is NSFW.
  nsfw: (post, rule) ->
    return @check(rule, post.data.over_18)
