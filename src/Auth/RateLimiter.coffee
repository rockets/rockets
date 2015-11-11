###
Rate limiter, responsible for:
  - Delaying request tasks to maintain a 1:1 request / second rate.
###
module.exports = class RateLimiter

  constructor: () ->
    @last = 0  # The time, in milliseconds, when the last task was initiated.
    @rate = 0  # The rate at which tasks may be scheduled.


  # Sets the time of the most recent task's initiation as the current time.
  tick: () ->
    log.info {event: 'ratelimit.queue.tick'}
    @last = Date.now()


  delay: (task) ->
    log.info {event: 'ratelimit.task'}

    delay = @getDelay()

    log.info {
      event: 'ratelimit.delay'
      delay: "#{delay}ms"
    }

    @last = Date.now()

    setTimeout task, delay or 1


  # Returns the amount of time to delay the current task by, 0 ~ 1000ms
  getDelay: () ->

    delay = Math.max(0, 1000 - (Date.now() - @last)) if @rate <= 1

    log.info {
      event: 'ratelimit.getdelay'
      last: @last
      rate: @rate
      delay: delay
    }

    return delay


 # Sets the allowed task schedule rate.
 # Allowed to process a number of 'tasks' within a given number of 'seconds'.
  setRate: (tasks, seconds) ->
    rate = if seconds > 0 then tasks / seconds else 1

    log.info {
      event: 'ratelimit.set'
      tasks: tasks
      seconds: seconds
      rate: rate
    }

    @rate = rate