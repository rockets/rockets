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
    @last = Date.now()


  # Delayed a task according to the current process rate.
  delay: (task) ->
    delay = @getDelay()
    @last = Date.now()
    setTimeout task, delay or 1


  # Returns the amount of time to delay the current task by, 0 ~ 1000ms
  getDelay: () ->
    return Math.max(0, 1000 - (Date.now() - @last)) if @rate <= 1


 # Sets the allowed task schedule rate.
 # Allowed to process a number of 'tasks' within a given number of 'seconds'.
  setRate: (tasks, seconds) ->
    @rate = if seconds > 0 then tasks / seconds else 1

    log.info 'rate.limit',
      tasks: tasks
      seconds: seconds
