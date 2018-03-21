/**
 *
 */
export default class Bool {

    constructor(expected) {
        this.expected = !! expected;
    }

    test(value) {
        return value == this.expected;
    }
}
