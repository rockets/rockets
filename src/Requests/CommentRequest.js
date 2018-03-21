/**
 * A task that fetches a listing of comments from reddit.com.
 */
import ModelTask from "./ModelRequest";

export default class CommentTask extends ModelTask {

    // Returns the fullname prefix for a comment, 't1'
    // See https://www.reddit.com/dev/api#fullnames
    getFullnamePrefix() {
        return 't1';
    }

    // The requests parameters for the initial request, to determine the starting
    // point from which to generate fullnames.
    getInitialParameters() {
        return {
            url: 'https://oauth.reddit.com/r/all/comments',
            params: {
                sort: 'new',
                limit: 1,
                raw_json: 1,
            }
        }
    }

    // The request parameters for all future 'reversed' requests.
    // These are used to fetch the newest models on reddit.com
    getReversedParameters() {
        return {
            url: 'https://oauth.reddit.com/r/all/comments',
            params: {
                sort: 'new',
                limit: ModelTask.REQUEST_LIMIT,
                raw_json: 1,
            }
        }
    }

    // The request parameters for all future 'forward' requests.
    // These are used to fetch the models newer than the most recently processed.
    getForwardParameters() {
        let fullnames = this.getFullnameString(this.latest + 1, ModelTask.REQUEST_LIMIT);

        return {
            url: 'https://oauth.reddit.com/api/info',
            params: {
                id: fullnames,
                limit: ModelTask.REQUEST_LIMIT,
                raw_json: 1,
            }
        }
    }

    // The request parameters for all future 'backlog' requests.
    // These are used to patch gaps between the newest models and the most recently
    // received models. Will only be called occasionally within the flow of a
    // 'reversed' model request.
    getBacklogParameters(start, length) {
        let fullnames = this.getFullnameString(start, length);

        return {
            url: 'https://oauth.reddit.com/api/info',
            params: {
                id: fullnames,
                limit: length,
                raw_json: 1
            }
        }
    }
}
