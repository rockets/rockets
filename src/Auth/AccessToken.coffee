###
Wrapper around a reddit OAuth2 access token response.
See https://github.com/reddit/reddit/wiki/OAuth2
###
module.exports = class AccessToken

  # Creates a new access token wrapper using decoded JSON data.
  constructor: (data) ->
    @token   = data.access_token
    @expires = data.expires_in + Date.now() // 1000


  # Determines whether this access token has expired.
  # Uses a 5 second safety period just to make sure.
  hasExpired: () ->
    return (@expires - Date.now() // 1000) < 5


  # Returns the request authorization headers for this token.
  getHeaders: () ->
    return bearer: @token
