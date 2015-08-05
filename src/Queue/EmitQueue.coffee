###
Queue which is responsible for:
  - Sending payloads to clients.
###
module.exports = class EmitQueue extends Queue

  # Processes an emit task (sends a model to a client).
  process: (task, done) ->
    task.client.send(task.model)
    done()
