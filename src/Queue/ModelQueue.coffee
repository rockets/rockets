###
Queue which is responsible for:
  - Sending models to worker processes.
###
module.exports = class ModelQueue extends Queue

  # Send a model to each worker.
  process: (model, next) ->

    # Log the model so that we can keep track of received models.
    log.info 'modelqueue.process', {
      model: model,
    }

    # Exclude deleted models entirely.
    if model.data.author?.toLowerCase() in ['[deleted]', '[removed]']
      return process.nextTick(next)

    # Determine which channel the model belongs to.
    switch model.kind
      when 't1' then channel = 'comments'
      when 't3' then channel = 'posts'

    # Unknown model kind or bad data.
    if not channel
      process.nextTick(next)
      return

    log.info 'modelqueue.channel', {
      channel: channel,
      workers: Object.keys(cluster.workers),
    }

    # Send the model to each worker.
    for id, worker of cluster.workers
      worker.send {channel, model}

    next()
