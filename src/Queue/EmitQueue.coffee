###
Queue which is responsible for:
  - Sending payloads to clients.
###
module.exports = class EmitQueue extends Queue

  # Processes an emit task (sends a model to a client).
  process: (task, next) ->
    try
        task.client.send(task.model)
    finally
        next()
