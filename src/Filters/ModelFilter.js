import {each, some} from "lodash";

/**
 * Base filter, used to determine if a subscription should receive a model.
 */
export default class ModelFilter {

    constructor(rules = {}) {
        this.rules = this.prepare(rules, this.schema());
    }

    /**
     *
     */
    schema() {
        return {};
    }

    /**
     *
     */
    prepare(rules, schema) {
        let prepared = {};

        //
        each(rules, (expected, key) => {
            if (key in schema) {
                prepared[key] = new (schema[key])(expected);
            }
        });

        return prepared;
    }

    /**
     * Validates a model against this rule, ie. determines if the model should
     * be sent to the client that owns the subscription that contains this rule.
     */
    test(model) {
        return some(this.rules, (rule, key) => rule.test(model[key]));
    }
}
