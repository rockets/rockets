/**
 *
 */
import Regex from "../Rules/Regex";
import Equal from "../Rules/Equal";
import Bool from "../Rules/Bool";
import ModelFilter from "./ModelFilter";

export default class CommentFilter extends ModelFilter {

    schema() {
        return {
            text:       Regex,
            subreddit:  Text,
            author:     Text,
            post:       Equal,
            root:       Bool,
        }
    }
}
