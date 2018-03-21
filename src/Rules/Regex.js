import {some, castArray} from "lodash";

/**
 *
 */
export default class Regex {

    constructor(pattern) {
        this.patterns = castArray(pattern).map((re) => new RegExp(re));
    }

    test(value) {
        return some(this.patterns, (re) => {
            return re && re.test(value);
        });
    }
}
