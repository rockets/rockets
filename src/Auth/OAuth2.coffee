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
      event: 'token.request'
    }

    options =
      username: process.env.CLIENT_ID
      password: process.env.CLIENT_SECRET
      data:
        grant_type: 'password'
        username: process.env.USERNAME
        password: process.env.PASSWORD

    restler.post('https://reddit.com/api/v1/access_token', options)
      .on('success', (data, response) =>

          @token = new AccessToken(data)

          log.info {
            event: 'token.created'
            token: @token.token
          }

      )
      .on('error', (err, response) ->
        log.error {
          message: 'Unexpected error during access token request'
          status: response?.statusCode
          error: err
        }
      )
      .on('fail', (data, response) ->
        log.error {
          message: 'Unexpected status code for access token request'
          status: response?.statusCode
        }
      )
      .on('complete', (result, response) =>
        log.info {
          event: 'token.response.complete'
        }

        callback(@token)
      )


  # Requests models from reddit.com using given request parameters.
  # Passes models to a handler or `false` if the request was unsuccessful.
  models: (parameters, handler) ->

    log.info {
      event: 'request.models'
      parameters: parameters
    }

    # Initialise blank headers
    parameters.headers = parameters.headers or {}

    # Wrap token authentication around the request
    @authenticate (token) =>

      # Don't make the request if the token is not valid
      if not token
        log.error {
          message: 'Access token is not set'
          parameters: parameters
        }

        return handler()

      # User agent should be the only header we need to set for a API requests.
      parameters.headers['User-Agent'] = process.env.USER_AGENT

      # Set the HTTP basic auth header for the request
      parameters.headers['Authorization'] = "Bearer #{@token.token}"

      @rate.delay () =>

        log.info {
          event: 'request'
          parameters: parameters
        }

        try

          restler.request(parameters.url, parameters)

            .on('success', (data, response) ->

              log.info {
                event: 'model.request.success'
              }

              try
                parsed = JSON.parse(data)

                # Make sure that the parsed JSON is also in the expected format, which
                # should be a standard reddit 'Listing'.
                if parsed.data and 'children' of parsed.data

                  # reddit doesn't always send results in the right order. This will
                  # sort the models by ascending ID, ie. from oldest to newest.
                  children = parsed.data.children.sort (a, b) ->
                    return parseInt(a.data.id, 36) - parseInt(b.data.id, 36)

                  log.info {
                    event: 'request.models.received'
                    count: children.length
                  }

                  handler(children)

                else
                  log.error {
                    message: 'No children found in parsed JSON response'
                    data: parsed
                  }

                  handler()

              catch exception

                log.error {
                  message: 'Something went wrong during response handling'
                  exception: exception
                  status: response?.statusCode
                }

                handler()

            )
            .on('error', (err, response) ->
              log.error {
                message: 'Unexpected request error'
                status: response?.statusCode
                error: err
              }

              handler()
            )
            .on('timeout', (ms) ->
              log.error {
                message: 'Request timed out'
                parameters: parameters
              }

              handler()
            )
            .on('abort', () ->
              log.error {
                message: 'Request was aborted'
                parameters: parameters
              }

              handler()
            )
            .on('fail', (data, response) ->

              log.error {
                message: 'Unexpected status code'
                status: response?.statusCode
                parameters: parameters
              }

              handler()
            )
            .on('complete', (result, response) =>

              log.info {
                event: 'model.request.complete'
                status: response?.statusCode
              }

              log.info {
                event: 'ratelimit.set'
                headers: response?.headers
              }

              # Set the rate limit allowance using the reddit rate-limit headers.
              # See https://www.reddit.com/1yxrp7
              @setRateLimit(response)
            )

        catch
          log.error {
              message: 'Something went wrong during the request?'
              parameters: parameters
            }


  # Attempts to set the allowed rate limit using a response
  setRateLimit: (response) ->
    if response?.headers
      try
        messages = response.headers['x-ratelimit-remaining']
        seconds  = response.headers['x-ratelimit-reset']

        @rate.setRate(messages, seconds)

        log.info {
          event: 'ratelimit'
          messages: messages
          seconds: seconds
        }

      catch exception
        message = 'Failed to set rate limit'

        log.error {
          message: message
          headers: response.headers
          exception: exception
        }
