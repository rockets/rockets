import {castArray, includes} from "lodash";

/**
 *
 */
export default class Equal {

    constructor(expected) {
        this.expected = castArray(expected);
    }

    test(value) {
        return includes(this.expected, value);
    }
}
