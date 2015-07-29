###
Base task for fetching models from reddit.com, responsible for:
  - Fetching a single recent model to start off with
  - Fetching subsequent models
  - Pushing fetched models onto a model queue
###
module.exports = class Task

  @LIMIT = 100

  constructor: (@oauth, @queue) ->
    @latest = null


  # Converts a decimal index to a reddit base36 'fullname'
  indexToFullname: (index) ->
    return @fullnamePrefix() + '_' + index.toString 36


  # Creates a comma-separated string list of all indices
  fullnames: (start, length) ->
    return [@indexToFullname(x) for x in [start...start + length]].join()


  # Converts a base36 ID to a base10 (decimal) ID
  idToIndex: (id) ->
    return parseInt id, 36


  # Pushes models onto the model queue.
  enqueue: (models, done) ->

    log.info {
      event: 'models',
      kind: @fullnamePrefix(),
      count: models.length,
      latency: (Date.now() / 1000) - models[models.length - 1].data.created_utc
    }

    @queue.push models
    done()


  # Fetches models using given parameters then feeds them to a model processor.
  fetch: (parameters, processor, done) ->
    @oauth.models parameters, (models) =>
      if models?.length > 0 then processor.call(@, models, done) else done()


  # Task generator for a 'forward' request
  forward: () ->
    return (done) =>
      if @latest then @fetchForward(done) else @fetchInitial(done)


  # Task generator for a 'reversed' request
  reversed: () ->
    return (done) =>
      if @latest then @fetchReversed(done) else @fetchInitial(done)


  # Fetches an initial starting point.
  fetchInitial: (done) ->
    @fetch @initialParameters(), @processInitial, done


  # Fetches models 'forward'
  fetchForward: (done) ->
    @fetch @forwardParameters(), @processForward, done


  # Fetches models 'reversed'
  fetchReversed: (done) ->
    @fetch @reversedParameters(), @processReversed, done


  # Processes the models from an initial request.
  # Sets the initial value of the most recently processed model.
  processInitial: (models, done) ->
    @latest = @idToIndex(models[0].data.id)
    done()


  # Processes the models from a 'forward' request.
  # Sets the current value of the most recently processed model.
  processForward: (models, done) ->

    # Set the latest model as the last model in the received list.
    @latest = @idToIndex(models[models.length - 1].data.id)

    # Push models onto the model queue (processed one by one)
    return @enqueue models, done


  # Processes the models from a 'reversed' request.
  # Sets the current value of the most recently processed model.
  processReversed: (models, done) ->

    # This is the newest of the new models
    newest = @idToIndex(models[models.length - 1].data.id)

    # Check if there actually is something new
    if newest <= @latest
      return done()

    # This is the base36 ID of the most recently processed model
    latestId = (@latest).toString(36)

    # Attempt to find where the most recently processed model occurs in the list
    # of new models. We can't just slice a range out of the array because there
    # may be gaps in the ID's.
    for index, model of models
      if model.data.id is latestId

        @latest = newest

        # Slice only the newest models, starting from but excluding the most
        # recently processed model.
        return @enqueue models[parseInt(index) + 1...], done

    # We couldn't find the most recently processed model in the list of new
    # models, which means that there's a backlog of models that lie in-between.

    # This is the 'oldest' of the new models.
    oldest = @idToIndex(models[0].data.id)

    # Process the backlog starting from the first model after the most recently
    # processed model, and ending on the model right before the oldest of the
    # new models.
    @fetchBacklog @latest + 1, oldest - 1, (backlog) =>
      @latest = newest

      # Append the models models to the back of the backlog models
      return @enqueue backlog.concat(models), done


  # Fetches a backlog of models starting from and including 'start', up to and
  # including 'end'. Calls 'done' with the list of fetched backlog models.
  fetchBacklog: (start, end, done) ->

    backlog = []

    # Fetch task
    fetch = (callback) =>
      length = Math.min(Task.LIMIT, end - start)

      @oauth.models @backlogParameters(start, length), (models) ->
        if models
          backlog = backlog.concat(models)

          # Move the start pointer forward. It's important that we don't update
          # this using the number of models, because there may be gaps in the
          # response which could result in a deadlock or missing data.
          start += length

        callback()

    # While there is a backlog, fetch, then call done with the models.
    async.whilst (() -> start < end), fetch, (() -> done(backlog))
