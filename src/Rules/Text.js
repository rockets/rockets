import {castArray, deburr, includes} from "lodash";

/**
 *
 */
export default class Text {

    constructor(expected) {
        this.expected = castArray(expected).map(this.normalize);
    }

    normalize(value) {
        return deburr(value).toLowerCase();
    }

    test(value) {
        return includes(this.expected, this.normalize(value));
    }
}
