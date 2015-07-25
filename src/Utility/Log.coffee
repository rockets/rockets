###
Wraps around bunyan to create a consistent logging interface.
###
module.exports = class Log

  constructor: () ->
    @loggers =

      # Info log
      info: bunyan.createLogger({
        name: 'rockets',
        streams: [
          {
            level: 'info',
            stream: process.stdout,
          },
        ]
      })

      # Error log
      error: bunyan.createLogger({
        name: 'rockets',
        streams: [
          {
            level: 'error',
            stream: process.stderr,
          },
        ]
      })


  # Log arbitrary arguments to the info log
  info: () ->
    @loggers.info.info arguments


  # Log arbitrary arguments to the error log
  error: () ->
    @loggers.error.error arguments
