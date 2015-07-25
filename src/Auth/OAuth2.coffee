###
Used to make authenticated requests to the reddit API. Responsible for:
  - Requesting an access token
  - Making sure the reddit rate-limit rules are followed
  - Making authenticated requests to the API

See https://github.com/reddit/reddit/wiki/OAuth2
###
module.exports = class OAuth2

  constructor: () ->
    @rate = new RateLimiter()
    @token = null


  # Wraps authentication around a callback which expects an access token.
  authenticate: (callback) ->

    # Use the current token if it's still valid.
    if @token and not @token.hasExpired()
      return callback(@token)

    log.info {
      event: 'auth',
    }

    options =
      url: 'https://www.reddit.com/api/v1/access_token'
      method: 'POST'
      auth:
        user: process.env.CLIENT_ID
        pass: process.env.CLIENT_SECRET
      form:
        grant_type: 'password'
        username: process.env.USERNAME
        password: process.env.PASSWORD

    # Request a new access token
    request options, (error, response, body) =>
      if response?.statusCode is 200
        try
          @token = new AccessToken(JSON.parse(body))
        catch exception
          message = 'Unexpected access token JSON response'
          log.error {message, error, response, body, exception}
      else
        message = 'Unexpected status code when requesting access token'
        log.error {message, error, response}

      callback(@token)


  # Attempts to set the allowed rate limit using a response
  setRateLimit: (response) ->
    if response?.headers
      try

        messages = response.headers['x-ratelimit-remaining']
        seconds  = response.headers['x-ratelimit-reset']

        @rate.setRate(messages, seconds)

        log.info {
          event: 'ratelimit',
          messages: messages,
          seconds: seconds,
        }

      catch exception
        message = 'Failed to set rate limit'
        log.error {message, response, exception}


  # Requests models from reddit.com using given request parameters.
  # Passes models to a handler or `false` if the request was unsuccessful.
  models: (parameters, handler) ->
    @request parameters, (error, response, body) ->

      # This is an important case because /by_id/ currently returns a 404 if
      # a list of id's didn't produce any models. This response is considered
      # a success, so just indicate that no models were found.
      if response?.statusCode is 404
        return handler([])

      # 200 is the only other success code.
      if response?.statusCode is 200

        # Attempt to parse the response JSON
        try
          parsed = JSON.parse(body)
        catch exception
          message = 'Failed to parse JSON response'
          log.error {message, error, response, body, parameters}

        # Make sure that the parsed JSON is also in the expected format, which
        # should be a standard reddit 'Listing'.
        if parsed.data and 'children' of parsed.data

          # reddit doesn't always send results in the right order. This will
          # sort the models by ascending ID, ie. from olderst to newest.
          return handler parsed.data.children.sort (a, b) ->
            return parseInt(a.data.id, 36) - parseInt(b.data.id, 36)

        else
          message = 'Children not found in parsed JSON response'
          log.error {message, error, response, body, parameters}
          return handler(false)

      else
        return handler(false)


  # Makes an authenticated request.
  request: (parameters, handler) ->

    # See https://github.com/reddit/reddit/wiki/API
    if not process.env.USER_AGENT
      return log.error 'User agent is not defined'

    log.info {
      event: 'request',
      parameters: parameters,
    }

    # Wrap token authentication around the request
    @authenticate (token) =>

      # Don't make the request if the token is not valid
      return handler() if not token

      # User agent should be the only header we need to set for a API requests.
      parameters.headers =
        'User-Agent': process.env.USER_AGENT

      # Set the HTTP basic auth headers for the request
      parameters.auth =
        bearer: @token.token

      # Schedule a request on the rate limit queue
      @rate.push (next) =>
        request parameters, (error, response, body) =>

          # Set the rate limit allowance using the reddit rate-limit headers.
          # See https://www.reddit.com/1yxrp7
          @setRateLimit(response)

          handler(error, response, body)
          next()
