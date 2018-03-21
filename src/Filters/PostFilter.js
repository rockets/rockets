import Regex from "../Rules/Regex";
import Text from "../Rules/Text";
import Bool from "../Rules/Bool";
import ModelFilter from "./ModelFilter";

/**
 *
 */
export default class PostFilter extends ModelFilter {

    schema() {
        return {
            title:        Regex,
            text:         Regex,
            subreddit:    Text,
            author:       Text,
            domain:       Text,
            url:          Text,
            nsfw:         Bool,
        }
    }
}
