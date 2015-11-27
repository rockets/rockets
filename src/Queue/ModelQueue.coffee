###
Queue which is responsible for:
  - Sending models to worker processes.
###
module.exports = class ModelQueue extends Queue

  # Send a model to each worker.
  process: (model, next) ->

    # Exclude deleted models entirely.
    if model.data.author?.toLowerCase() not in ['[deleted]', '[removed]']
      switch model.kind
        when 't1' then channel = 'comments'
        when 't3' then channel = 'posts'

      if not channel
        process.nextTick(next)
        return

      # Log the model so that we can keep track of received models.
      log.model(model)

      # Send the model to each worker.
      for id, worker of cluster.workers
        worker.send {channel, model}

      next()
