###
Wraps around bunyan to create a consistent logging interface.
###
module.exports = class Log

  #
  @errorHandler = (err) ->
    log.error {
      error: err or 'Unknown',
      stack: err?.stack
    }


  # Bundle log data into a consistent format.
  bundle: (data) ->
    return JSON.stringify {
      date: new Date().toLocaleDateString(),
      time: new Date().toTimeString(),
      data: data,
    }


  # Log arbitrary arguments to the info log
  info: () ->
    console.info @bundle(arguments)


  # Log arbitrary arguments to the error log
  error: () ->
    console.error @bundle(arguments)

    # Also print a stack trace to stderr
    console.trace()
