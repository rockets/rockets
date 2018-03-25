import queue from "async/queue";

export default class Queue {

    constructor() {
        this.queue = queue((task, next) => task(next), this.concurrency());
    }

    /**
     * @returns {number}
     */
    concurrency() {
        return 1;
    }

    /**
     * @param {Function} task
     * @param {Function} done
     */
    push(task, done) {
        this.queue.push(task, done);
    }
}
