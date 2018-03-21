/*
Base task for fetching models from reddit.com, responsible for:
  - Fetching a single recent model to start off with
  - Fetching subsequent models
  - Pushing fetched models onto a model queue

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

*/

import {get, join, last, map, range} from "lodash";
import {whilst} from "async";

export default class ModelTask {

   /**
    * @param {Client} http
    */
    constructor(http) {
      this.http = http;
      this.latestIndex = null;
    }

    stats() {
        return {};
    }

    static get REQUEST_LIMIT() {
        return 100;
    }

    /**
     * @abstract
     */
    getFullnamePrefix() {}
    getInitialParameters() {}
    getForwardParameters() {}
    getReversedParameters() {}
    getBacklogParameters(start, range) {}

    // Converts a decimal index to a reddit base36 'fullname'
    indexToFullname(index) {
      return this.getFullnamePrefix() + '_' + index.toString(36);
    }

    // Converts a base36 ID to a base10 (decimal) ID
    idToIndex(id) {
      return parseInt(id, 36);
    }

    getFullnameRange(start, length) {
        return map(range(start, start + length), this.indexToFullname);
    }

    // Creates a comma-separated string list of all indices
    getFullnameString(start, length) {
        return join(this.getFullnameRange(start, length), ',');
    }

    // // Pushes models onto the model queue.
    // enqueue(models) {
    //     this.queue.push(models, () => {
    //         console.error('finished processing models');
    //     });
    // }

    /**
     *
     * @param {Object} response
     */
    getModelsFromResponse(response) {
        let models = get(response, ['data', 'data', 'children']);

        //
        if (!models) {
            throw new Error('No models in response data');
        }

        // Reddit doesn't always send results in the right order.
        // Sort the models by ascending ID, ie. from oldest to newest.
        models = models.sort((a, b) => {
            return this.idToIndex(a.data.id) - this.idToIndex(b.data.id);
        });

        return models;
    }

    // Fetches models using given parameters.
    fetch(parameters) {
        return this
            .http
            .send(parameters)
            .then(this.getModelsFromResponse)
    }

    /**
     * Task generator for a 'forward' request
     */
    forward() {
        return this.latest ? this.fetchForward() : this.fetchInitial();
    }

    /**
     * Task generator for a 'reversed' request
     */
    reversed() {
        return this.latest ? this.fetchReversed() : this.fetchInitial();
    }

    // Fetches an initial starting point.
    fetchInitial() {
        return this
            .fetch(this.getInitialParameters())
            .then((models) => this.processInitial(models))
    }
    // Fetches models 'forward'.
    fetchForward() {
        return this
            .fetch(this.getForwardParameters())
            .then((models) => this.processForward(models))
    }

    // Fetches models 'reversed'.
    fetchReversed() {
        return this
            .fetch(this.getReversedParameters())
            .then((models) => this.processReversed(models))
    }

    // Processes the models from an initial request.
    // Sets the initial value of the most recently processed model.
    processInitial(models) {
        this.latest = this.idToIndex(models[0].data.id);

        return models;
    }

    // Processes the models from a 'forward' request.
    // Sets the current value of the most recently processed model.
    processForward(models) {
        this.latest = this.idToIndex(models[models.length - 1].data.id);

        return models;
    }

    /**
     *
     * @param {Array} models
     *
     * @returns {*}
     */
    processReversed(models) {

        // This is the newest of the new models
        const newIndex = this.idToIndex(last(models).data.id);

        // Skip if the index we found is older than the most recent.
        if (newIndex <= this.latestIndex) {
            return [];
        }

        // This is the base36 ID of the most recently processed model
        const currentLatestId = (this.latestIndex).toString(36);

        // Attempt to find where the most recently processed model occurs in the list
        // of new models. We can't just slice a range out of the array because there
        // may be gaps in the ID's.
        for (let index in models) {

            // We've either found the most recent, or one that came before it.
            if (models[index].data.id <= currentLatestId) {

                // Update the latest index that we've processed.
                this.latestIndex = newIndex;

                return models.slice(parseInt(index) + 1);
            }
        }

        // We couldn't find the most recently processed model in the list of new
        // models, which means that there's a backlog of models that lie in-between.

        // Process the backlog starting from the first model after the most recently
        // processed model, and ending on the model right before the oldest of the
        // new models that we just received.
        let start = this.latestIndex + 1;
        let end   = this.idToIndex(models[0].data.id);

        return this.fetchBacklog(start, end).then((backlog) => {
            this.latestIndex = newIndex;

            // Append the models models to the back of the backlog models
            return backlog.concat(models);
        });
    }

    // Fetches a backlog of models starting from and including 'start', up to and
    // including 'end'. Calls 'done' with the list of fetched backlog models.
    fetchBacklog(start, end) {
        let backlog = [];

        return new Promise((resolve, reject) => {

            /**
             *
             */
            const backtrack = (done) => {
                let range = Math.min(ModelTask.REQUEST_LIMIT, end - start);

                return this
                    .fetch(this.getBacklogParameters(start, range))
                    .then((models) => {
                        backlog = backlog.concat(models || []);

                        // Move the start pointer forward. It's important that we don't update
                        // this using the number of models, because there may be gaps in the
                        // response which could result in a deadlock or missing data.
                        start += range;

                        done();
                    });
            };

            // While there is a backlog, fetch, then call done with the models.
            whilst(() => start < end, backtrack, () => resolve(backlog));
        });
    }
}
