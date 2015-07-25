###
Master process, responsible for:
  - Forking socket server workers
  - Initiating request tasks
###
module.exports = class Master

  constructor: () ->
    @queue   = new ModelQueue()
    @oauth   = new OAuth2()

    @fork()
    @run()


  # Fork workers, which will each create a `Worker` process.
  fork: () ->
    cluster.fork() for _ in [0...(os.cpus().length-1)]


  # Builds request tasks, and starts the loop to process them indefinitely.
  run: () ->

    # Cache this so that we don't re-create it every time
    tasks = @tasks()

    # Run all tasks in series, forever.
    async.forever (next) ->
      async.series tasks, next


  # Returns an array of model fetch tasks to run
  tasks: () ->

    comments = new CommentTask(@oauth, @queue)
    posts = new PostTask(@oauth, @queue)

    # This will be the task schedule to keep iterating through.
    schedule = []

    # Alternate between forward post requests and reversed comment requests.
    for _ in [0...60]
      schedule = schedule.concat [
        posts.forward()
        comments.reversed()
      ]

    # After 60 seconds, do a reversed post request.
    schedule.push posts.forward()

    return schedule
