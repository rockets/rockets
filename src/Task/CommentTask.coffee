###
A task that fetches a listing of comments from reddit.com.
###
module.exports = class CommentTask extends Task

  # Returns the fullname prefix for a comment, 't1'
  # See https://www.reddit.com/dev/api#fullnames
  fullnamePrefix: () ->
    't1'


  # The requests parameters for the initial request, to determine the starting
  # point from which to generate fullnames.
  initialParameters: () ->
    url: 'https://oauth.reddit.com/r/all/comments'
    qs:
      sort: 'new'     #
      limit: 1        #
      raw_json: 1     # We don't want the JSON data to be encoded.


  # The request parameters for all future 'reversed' requests.
  # These are used to fetch the newest models on reddit.com
  reversedParameters: () ->
    url: 'https://oauth.reddit.com/r/all/comments'
    qs:
      sort: 'new'         #
      limit: Task.LIMIT   # The maximum amount of results we'd like to receive.
      raw_json: 1         # We don't want the JSON data to be encoded.


  # The request parameters for all future 'forward' requests.
  # These are used to fetch the models newer than the most recently processed.
  forwardParameters: () ->
    ids = @fullnames(@latest + 1, Task.LIMIT)

    url: 'https://oauth.reddit.com/api/info'
    qs:
      id: fullnames       # Comma-separated list of comment fullnames.
      limit: Task.LIMIT   # The maximum amount of results we'd like to receive.
      raw_json: 1         # We don't want the JSON data to be encoded.


  # The request parameters for all future 'backlog' requests.
  # These are used to patch gaps between the newest models and the most recently
  # received models. Will only be called occasionally within the flow of a
  # 'reversed' model request.
  backlogParameters: (start, length) ->
    fullnames = @fullnames(start, length)

    url: 'https://oauth.reddit.com/api/info'
    qs:
      id: fullnames   # Comma-separated list of comment fullnames.
      limit: length   # The maximum amount of results we'd like to receive.
      raw_json: 1     # We don't want the JSON data to be encoded.
