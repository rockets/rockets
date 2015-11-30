###
Wraps around bunyan to create a consistent logging interface.
###
module.exports = class Log

  constructor: () ->

    # For general logging.
    @logger = new winston.Logger
      transports: [
        new (winston.transports.File)({
          name:             'info'
          filename:         'logs/info.log'
          level:            'info'
          timestamp:        false
        }),
        new (winston.transports.File)({
          name:             'error'
          filename:         'logs/error.log'
          level:            'error'
          timestamp:        false
          handleExceptions: true
        }),
      ],
      exitOnError: false


    # For logging posts
    @posts = new winston.Logger
      transports: [
        new (winston.transports.File)({
          name:      'posts'
          filename:  'logs/posts.log'
          level:     'info'
          timestamp: false
        }),
      ],

    # For logging comments
    @comments = new winston.Logger
      transports: [
        new (winston.transports.File)({
          name:      'comments'
          filename:  'logs/comments.log'
          level:     'info'
          timestamp: false
        }),
      ],

  # Bundle log data into a consistent format.
  bundle: (data) ->
    return {
      date: new Date().toLocaleDateString()
      time: new Date().toTimeString()
      unix: Date.now() // 1000
      data: (if data and data.length is 1) then data[0] else data
    }


  # Log arbitrary arguments to the info log
  info: (message, metadata) ->
    @logger.log 'info', message, @bundle(metadata)


  # Log arbitrary arguments to the error log
  error: (message, metadata) ->
    @logger.log 'error', message, @bundle(metadata)


  # Log a model to its respective log.
  model: (model) ->
    switch model.kind
      when 't1' then logger = @comments
      when 't3' then logger = @posts

    if logger
      logger.log 'info', @bundle({
        fullname: model.data.name
        pk: parseInt(model.data.id, 36)
        latency: (Date.now() // 1000) - model.data.created_utc
      })
