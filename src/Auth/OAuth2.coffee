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

    # Reset token.
    @token = false

    parameters =
      username: process.env.CLIENT_ID
      password: process.env.CLIENT_SECRET
      data:
        grant_type: 'password'
        username: process.env.USERNAME
        password: process.env.PASSWORD

      # 5s request timeout
      timeout: 5000

    restler.post('https://reddit.com/api/v1/access_token', parameters)

      # Called when an access token request is successful.
      .on 'success', (data, response) =>
        @token = new AccessToken(data)

      # Called when an access toen
      .on 'timeout', (ms) ->
        log.error {
          message: 'Access token request timeout'
        }

      # Called when the request errored, which is not the same as a failed
      # request. This should indicate that something should be fixed.
      .on 'error', (err, response) ->
        log.error {
          message: 'Unexpected error during access token request'
          status: response?.statusCode
          error: err
        }

      # Called when the request was not successful, which is most likely due to
      # Reddit being down or under maintenance.
      .on 'fail', (data, response) ->
        log.error {
          message: 'Unexpected status code for access token request'
          status: response?.statusCode
        }

      # Called when the request has completed, regardless of whether it was
      # successful. Use whatever token state we currently have.
      .on 'complete', (result, response) =>
        callback(@token)



  _models: (parameters, handler) ->
    return restler.request(parameters.url, parameters)

      # Called when the request was successful.
      .on 'success', (data, response) ->
        try
          parsed = JSON.parse(data)

          # Make sure that the parsed JSON is also in the expected format, which
          # should be a standard reddit 'Listing'.
          if not parsed.data or 'children' not of parsed.data
            return handler()

          # Reddit doesn't always send results in the right order. This will
          # sort the models by ascending ID, ie. from oldest to newest.
          handler parsed.data.children.sort (a, b) ->
            return parseInt(a.data.id, 36) - parseInt(b.data.id, 36)

        catch exception
          handler()

      # Called when the request errored, which is not the same as a failed
      # request. This should indicate that something should be fixed.
      .on 'error', (err, response) ->
        log.error {
          message: 'Unexpected request error'
          status: response?.statusCode
          error: err
        }

        handler()

      # Called when the request times out.
      .on 'timeout', (ms) ->
        log.error {
          message: 'Request timed out'
          parameters: parameters
        }

        handler()

      # Called when the request is aborted, most likely by timeout abort.
      .on 'abort', () ->
        log.error {
          message: 'Request was aborted'
          parameters: parameters
        }

        handler()

      # Called when the request was not successful, which is most likely due to
      # Reddit being down or under maintenance.
      .on 'fail', (data, response) ->
        log.error {
          message: 'Unexpected status code'
          status: response?.statusCode
          parameters: parameters
        }

        handler()


      # Called when the request has been completed, regardless of whether it
      # succeeded. It's important to set the rate limit using failed request
      # responses as well, as they count towards the allowed usage.
      .on 'complete', (result, response) =>

        # Set the rate limit allowance using the reddit rate-limit headers.
        # See https://www.reddit.com/1yxrp7
        if response
          @setRateLimit(response)



  # Requests models from reddit.com using given request parameters.
  # Passes models to a handler or `false` if the request was unsuccessful.
  models: (parameters, handler) ->

    # Initialise blank headers
    parameters.headers = parameters.headers or {}

    # Wrap token authentication around the request
    @authenticate (token) =>

      # Don't make the request if the token is not valid
      if not token
        return handler()

      # 5s request timeout.
      parameters.timeout = 5000

      # Disable connection pooling.
      parameters.agent = false

      # User agent should be the only header we need to set for a API requests.
      parameters.headers['User-Agent'] = process.env.USER_AGENT

      # Set the OAuth2 access token.
      parameters.accessToken = @token.token

      # Schedule a rate-limited model request, wrapped in a 10 second fallback
      # timeout in case something goes wrong internally.
      @rate.delay () =>
        request = false

        cancel = () ->
          if request
            request.abort()
          else
            handler()

        # 10s fallback timeout.
        timeout = setTimeout cancel, (10 * 1000)

        request = @_models parameters, (children) ->
          clearTimeout(timeout)
          handler(children)


  # Attempts to set the allowed rate limit using a response
  setRateLimit: (response) ->
    if response?.headers
      messages = response.headers['x-ratelimit-remaining']
      seconds  = response.headers['x-ratelimit-reset']

      @rate.setRate(messages, seconds)
