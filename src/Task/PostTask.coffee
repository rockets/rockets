###
A task that fetches the a listing of posts from reddit.com
###
module.exports = class PostTask extends Task

  # Returns the fullname prefix for a post, 't3'
  # See https://www.reddit.com/dev/api#fullnames
  fullnamePrefix: () ->
    't3'


  # The requests parameters for the initial request, to determine the starting
  # point from which to generate fullnames.
  initialParameters: () ->
    url: 'https://oauth.reddit.com/r/all/new'
    qs:
      limit: 1        #
      raw_json: 1     # We don't want the JSON data to be encoded.


  # The request parameters for all future 'reversed' requests.
  # These are used to fetch the newest models on reddit.com
  reversedParameters: () ->
    url: 'https://oauth.reddit.com/r/all/new'
    qs:
      limit: Task.LIMIT   # The maximum amount of results we'd like to receive.
      raw_json: 1         # We don't want the JSON data to be encoded.


  # The request parameters for all future 'forward' requests.
  # These are used to fetch the models newer than the most recently processed.
  forwardParameters: () ->
    fullnames = @fullnames(@latest + 1, Task.LIMIT)

    url: "https://oauth.reddit.com/by_id/#{fullnames}"
    qs:
      limit: Task.LIMIT   # The maximum amount of results we'd like to receive.
      raw_json: 1         # We don't want the JSON data to be encoded.


  # The request parameters for all future 'backlog' requests.
  # These are used to patch gaps between the newest models and the most recently
  # received models. Will only be called occasionally within the flow of a
  # 'reversed' model request.
  backlogParameters: (start, length) ->
    fullnames = @fullnames(start, length)

    url: "https://oauth.reddit.com/by_id/#{fullnames}"
    qs:
      limit: length    # The maximum amount of results we'd like to receive.
      raw_json: 1     # We don't want the JSON data to be encoded.
