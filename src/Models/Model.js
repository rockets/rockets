export default class Model {

    constructor(data) {
        this.data = data;
    }

    toJSON() {
        return this.data;
    }
}
