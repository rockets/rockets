import Model from "./Model";
import {get} from "lodash";

export default class Post extends Model {

    get title() {
        return get(this.data, ['data', 'title']);
    }

    get text() {
        return get(this.data, ['data', 'selftext']);
    }

    get subreddit() {
        return get(this.data, ['data', 'subreddit']);
    }

    get author() {
        return get(this.data, ['data', 'author']);
    }

    get domain() {
        return get(this.data, ['data', 'domain']);
    }

    get url() {
        return get(this.data, ['data', 'url']);
    }

    get nsfw() {
        return get(this.data, ['data', 'over_18']);
    }
}
