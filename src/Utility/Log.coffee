###
Wraps around bunyan to create a consistent logging interface.
###
module.exports = class Log

  constructor: () ->

    # For general logging.
    @logger = new winston.Logger {
      transports: [
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
      ],
      exitOnError: false
    }

    # For logging posts
    @posts = new winston.Logger {
      transports: [
        new (winston.transports.File)({
          name:             'posts'
          filename:         'logs/posts.log'
          level:            'info'
          prettyPrint:      true
        }),
      ],
    }

    # For logging comments
    @comments = new winston.Logger {
      transports: [
        new (winston.transports.File)({
          name:             'comments'
          filename:         'logs/comments.log'
          level:            'info'
          prettyPrint:      true
        }),
      ],
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


  # Log a model to its respective log.
  model: (model) ->
    switch model.kind
      when 't1' then logger = @comments
      when 't3' then logger = @posts

    if logger
      logger.log 'info', @bundle({
        fullname: model.data.name,
        pk: parseInt(model.data.id, 36)
      })
