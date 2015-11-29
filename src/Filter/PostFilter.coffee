###
Filter for a post model.
###
module.exports = class PostFilter extends Filter

  # These are the supported keys and expected types for this filter.
  schema: () ->
    contains:     Filter.REGEX
    subreddit:    Filter.STRING_I
    author:       Filter.STRING_I
    domain:       Filter.STRING_I
    url:          Filter.STRING_I
    nsfw:         Filter.BOOLEAN


  # Checks if a post contains any of the patterns in the rule.
  contains: (post, rule) ->
    return @check(rule, "#{post.data.title} #{post.data.selftext}")


  # Checks if a post's subreddit matches any of the values in the rule.
  subreddit: (post, rule) ->
    return @check(rule, post.data.subreddit)


  # Checks if a post's user/author matches any of the values in the rule.
  author: (post, rule) ->
    return @check(rule, post.data.author)


  # Checks if a post's domain matches any of the domains in the rule.
  domain: (post, rule) ->
    return @check(rule, post.data.domain)


  # Checks if a post's URL matches any of the URL's in the rule.
  url: (post, rule) ->
    return @check(rule, post.data.url)


  # Checks if the rule contains whether a post is NSFW.
  nsfw: (post, rule) ->
    return @check(rule, post.data.over_18)
