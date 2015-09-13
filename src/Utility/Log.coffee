###
Wraps around bunyan to create a consistent logging interface.
###
module.exports = class Log

  constructor: () ->
    @logger = new winston.Logger {

      #
      transports: [
        new (winston.transports.Console)({
          level:            'debug'
          prettyPrint:      true
        }),
        new (winston.transports.File)({
          name:             'info'
          filename:         'logs/info.log'
          level:            'info'
          prettyPrint:      true
        }),
        new (winston.transports.File)({
          name:             'error'
          filename:         'logs/error.log'
          level:            'error'
          prettyPrint:      true
          handleExceptions: true
        }),
        new (winston.transports.File)({
          name:             'all'
          filename:         'logs/all.log'
          level:            'debug'
          prettyPrint:      true
          handleExceptions: true
        }),
      ],

      #
      exitOnError: false
    }

  # Bundle log data into a consistent format.
  bundle: (data) ->
    return {
      date: new Date().toLocaleDateString(),
      time: new Date().toTimeString(),
      data: if data.length is 1 then data[0] else data,
    }


  # Log arbitrary arguments to the info log
  info: () ->
    @logger.log 'info', @bundle(arguments)


  # Log arbitrary arguments to the error log
  error: () ->
    @logger.log 'error', @bundle(arguments)

    # Also print a stack trace to stderr
    console.trace()
