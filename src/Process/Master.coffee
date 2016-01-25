###
Master process, responsible for:
  - Forking socket server workers
  - Initiating request tasks
###
module.exports = class Master

  constructor: () ->
    @fork()
    @run()


  # Fork workers, which will each create a `Worker` process.
  fork: () ->
    cluster.fork() for _ in [0...(os.cpus().length-1)]

    cluster.on 'exit', (worker, code, signal) ->
      log.info 'process.master.exit', {
        worker: worker.process.pid,
        code: code,
        signal: signal,
      }

      # Fork again because the worker died.
      cluster.fork()


  # Returns an array of model fetch tasks to run
  run: () ->
    oauth = new OAuth2()
    queue = new ModelQueue()

    comments = new CommentTask(oauth, queue)
    posts    = new PostTask(oauth, queue)

    # This will be the task schedule to keep iterating through.
    tasks = []

    for _ in [0...20]
      tasks.push comments.reversed()
      tasks.push posts.forward()

    tasks.push posts.reversed()

    # Run all tasks in series, forever.
    async.forever (next) ->
      async.series tasks, next


    ###
    Forward requests
    ================
    Fetches models by requesting info on future ID's. All tasks keep track of
    the most recently processed model, so bulk ID requests are made using that
    id followed by the next 100 successive ID's.

    Reversed requests
    =================
    Fetches models from newest to oldest, and uses 'forward' requests to patch
    the gaps that occur when the newest model in the response is too far ahead
    of the most recently processed model. For example, if we just processed
    ID '100', then receive ID '220', that means that there has been ~120 models
    since, creating a gap between '100' and '120' due to the 100 model limit.
    By requesting 101 -> 120, we patch the 'backlog' gap using forward requests.

    Posts
    =====
    Requesting posts in reverse is not ideal because reddit caches the results
    of /r/all/new for 60 seconds (even when using the API). Posts therefore have
    to be requested forward by requesting info on future ID's. This yields posts
    very soon after they are created (therefore low latency), but there is a
    risk of encountering a deadzone where the list of ID's will never resolve.
    The solution is to do a reversed post request every ~60 seconds, just to
    check that things are still on track.

    Comments
    ========
    Requesting comments in reverse is ideal, because reddit does not cache the
    results. We just keep requesting in reverse indefinitely.
    ###
