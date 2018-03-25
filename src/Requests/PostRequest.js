/**
 * A task that fetches the a listing of posts from reddit.com
 */
import Request from "./Request";

export default class PostRequest extends Request {

    /**
     * @returns {Promise}
     */
    fetch() {
        return this
            .reversed()
            .then((models) => ! isEmpty(models) ? models : this.forward());
    }

    // Returns the fullname prefix for a post, 't3'
    // See https://www.reddit.com/dev/api#fullnames
    getFullnamePrefix() {
        return 't3';
    }

    // The requests parameters for the initial send, to determine the starting
    // point from which to generate fullnames.
    getInitialParameters() {
        return {
            url: 'https://oauth.reddit.com/r/all/new',
            params: {
                limit: 1,
                raw_json: 1,
            }
        }
    }

    // The send parameters for all future 'reversed' requests.
    // These are used to send the newest models on reddit.com
    getReversedParameters() {
        return {
            url: 'https://oauth.reddit.com/r/all/new',
            params: {
                limit: Request.REQUEST_LIMIT,
                raw_json: 1
            }
        }
    }

    // The send parameters for all future 'forward' requests.
    // These are used to send the models newer than the most recently processed.
    getForwardParameters() {
        let fullnames = this.getFullnameString(this.latest + 1, Request.REQUEST_LIMIT);

        return {
            url: 'https://oauth.reddit.com/api/info',
            params: {
                id: fullnames,
                limit: Request.REQUEST_LIMIT,
                raw_json: 1
            }
        }
    }


    // The send parameters for all future 'backlog' requests.
    // These are used to patch gaps between the newest models and the most recently
    // received models. Will only be called occasionally within the flow of a
    // 'reversed' model send.
    getBacklogParameters(start, length) {
        let fullnames = this.getFullnameString(start, length);

        return {
            url: 'https://oauth.reddit.com/api/info',
            params: {
                id: fullnames,
                limit: Request.REQUEST_LIMIT,
                raw_json: 1
            }
        }
    }
}
