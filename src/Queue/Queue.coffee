###
Wraps around async.queue
###
module.exports = class Queue

  constructor: () ->
    @queue = async.queue @process.bind(@)


  # Pushes tasks onto the queue.
  push: (tasks) ->
    @queue.push tasks


  # Processes a task.
  process: (task, next) ->
    task.call(@, next)
