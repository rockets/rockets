###
Wraps around bunyan to create a consistent logging interface.
###
module.exports = class Log

  constructor: () ->
    @logger = new winston.Logger {

      #
      transports: [
        # new (winston.transports.Console)({
        #   name:             'console'
        #   handleExceptions: true
        #   json:             true
        #   level:            'verbose'
        # }),
        new (winston.transports.File)({
          name:             'info'
          filename:         'info.log'
          level:            'info'
          handleExceptions: true
          json:             true
        }),
        new (winston.transports.File)({
          name:             'error'
          filename:         'error.log'
          level:            'error'
          handleExceptions: true
          json:             true
        })
      ],

      #
      exitOnError: false
    }


  # Bundle log data into a consistent format.
  bundle: (data) ->
    return JSON.stringify {
      date: new Date().toLocaleDateString(),
      time: new Date().toTimeString(),
      data: if data.length is 1 then data[0] else data,
    }


  # Log arbitrary arguments to the info log
  info: () ->
    @logger.info @bundle(arguments)


  # Log arbitrary arguments to the error log
  error: () ->
    @logger.error @bundle(arguments)

    # Also print a stack trace to stderr
    # console.trace()
