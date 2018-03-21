import Model from "./Model";
import {get, startsWith} from "lodash";

export default class Comment extends Model {

    get text() {
        return get(this.data, ['data', 'body']);
    }

    get subreddit() {
        return get(this.data, ['data', 'subreddit']);
    }

    get author() {
        return get(this.data, ['data', 'author']);
    }

    get parent_id() {
        return get(this.data, ['data', 'parent_id']);
    }

    get is_root() {
        return startsWith('t3', this.parent_id);
    }

    get post_id() {
        return get(this.data, ['data', 'link_id']);
    }
}
