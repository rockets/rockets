###
Filter for a comment model.
###
module.exports = class CommentFilter extends Filter

  # These are the supported keys and expected types for this filter.
  schema: () ->
    contains:     Filter.REGEX
    author:       Filter.STRING
    subreddit:    Filter.STRING
    post:         Filter.STRING
    root:         Filter.BOOLEAN


  # Checks if a comment contains any of the patterns in the filter.
  contains: (comment, regex) ->
    return regex and regex.test(comment.data.body)


  # Checks if a comment's post matches any of the fullnames in the filter.
  post: (comment, filter) ->
    return @check(filter, comment.data.link_id)


  # Checks if the filter contains whether a comment is a root comment.
  root: (comment, filter) ->
    return @check(filter, comment.data.parent_id[0...2] is 't3')
