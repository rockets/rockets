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
        grant_type: 'client_credentials'

    restler.post('https://reddit.com/api/v1/access_token', options)
      .on('success', (data, response) =>

          log.info {
            event: 'token.response'
            data: data
          }

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
          data: data
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
          .on('fail', (data, response) ->

            log.error {
              message: 'Unexpected status code'
              status: response?.statusCode
              data: data
            }

            handler()
          )
          .on('complete', (result, response) =>

            log.info {
              event: 'model.request.complete'
              result: result
              status: response?.statusCode
            }

            log.info {
              event: 'ratelimit.set.before'
              headers: response?.headers
            }

            # Set the rate limit allowance using the reddit rate-limit headers.
            # See https://www.reddit.com/1yxrp7
            @setRateLimit(response)

            log.info {
              event: 'ratelimit.set.after'
              headers: response?.headers
            }
          )


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
          message: 'Failed to set rate limit'
          headers: response.headers
          exception: exception
        }


  # # Adds a new request to the rate limit queue, where handler expects parameters
  # # error, response, and body.
  # enqueueRequest: (parameters, handler) ->

  #   # Schedule a request on the rate limit queue
  #   @rate.push (next) =>

  #     log.info {
  #       event: 'request'
  #       parameters: parameters
  #     }

  #     restler.request(parameters.url, parameters)
  #       .on('success', (data, response) ->

  #         try

  #            # Trying to determine where we're stalling
  #           log.info {
  #             event: 'request.call.handler'
  #             response: response
  #             data: data
  #           }

  #           handler(JSON.decode(data))

  #           # Trying to determine where we're stalling
  #           log.info {
  #             event: 'request.after.handler'
  #           }

  #         catch exception
  #           log.error {
  #             message: 'Something went wrong during response handling'
  #             exception: exception
  #             response: response
  #           }

  #           # ??
  #           handler()
  #           next()

  #       )
  #       .on('error', (err, response) ->
  #         log.error {
  #           message: 'Unexpected request error'
  #           response: response
  #           error: err
  #         }

  #         handler()
  #       )
  #       .on('fail', (data, response) ->

  #         log.error {
  #           message: 'Unexpected status code'
  #           response: response
  #           data: data
  #         }

  #         handler()
  #       )
  #       .on('complete', (result, response) ->

  #         log.info {
  #           event: 'ratelimit.set.before'
  #           headers: response?.headers
  #         }

  #         # Set the rate limit allowance using the reddit rate-limit headers.
  #         # See https://www.reddit.com/1yxrp7
  #         @setRateLimit(response)

  #         log.info {
  #           event: 'ratelimit.set.after'
  #           headers: response?.headers
  #         }

  #         # Trying to determine where we're stalling
  #         log.info {
  #           event: 'request.try.handler'
  #           headers: response?.headers
  #         }

  #         # Trying to determine where we're stalling
  #         log.info {
  #           event: 'request.next'
  #         }

  #         next()
  #       )
