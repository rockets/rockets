###
Queue which is responsible for:
  - Sending payloads to clients.
###
module.exports = class EmitQueue extends Queue

  # Processes an emit task (sends a payload to a client).
  process: (task, done) ->
    task.client.send(task.payload, done)
