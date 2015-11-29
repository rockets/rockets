###
Filter for a comment model.
###
module.exports = class CommentFilter extends Filter

  # These are the supported keys and expected types for this filter.
  schema: () ->
    contains:     Filter.REGEX
    subreddit:    Filter.STRING_I
    author:       Filter.STRING_I
    post:         Filter.STRING
    root:         Filter.BOOLEAN


  # Checks if a comment contains any of the patterns in the rule.
  contains: (comment, rule) ->
    return @check(rule, comment.data.body)


  # Checks if a comment's subreddit matches any of the values in the rule.
  subreddit: (comment, rule) ->
    return @check(rule, comment.data.subreddit)


  # Checks if a comment's user/author matches any of the values in the rule.
  author: (comment, rule) ->
    return @check(rule, comment.data.author)


  # Checks if a comment's post matches any of the fullnames in the rule.
  post: (comment, rule) ->
    return @check(rule, comment.data.link_id)


  # Checks if the rule requires whether a comment is a root comment.
  root: (comment, rule) ->
    return @check(rule, comment.data.parent_id[0...2] is 't3')
