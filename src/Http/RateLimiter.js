/**
 *
 */
export default class RateLimiter {

  constructor(rate) {
      this.last = 0;  // When the last task was initiated (in ms).
      this.rate = 0;  // The rate at which tasks may be scheduled.
  }

  // Delayed a task according to the current process rate.
  limit() {
      return new Promise((resolve) => {
          setTimeout(resolve, this.getDelay());
      }).then(() => {
          this.last = Date.now();
      });
  }

  /**
    * Minimum amount of milliseconds between each task.
    *
    * @param rate
    */
  setMinimumTimeBetweenTasks(rate) {
      this.rate = Math.max(0, rate);
  }

  /**
   * Returns the amount of time to delay the current task by.
   */
  getDelay() {
      return Math.max(0, this.rate - (Date.now() - this.last));
  }
}
