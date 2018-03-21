/*
A container for pairing a client to a filter, managed by a channel.
*/

/**
 * @property {SocketClient} client
 * @property {Object} filters
 */
export default class Subscription {

    constructor(client, filters) {
        this.client  = client;
        this.filters = filters;
    }

    /**
     * @returns {SocketClient}
     */
    getClient() {
        return this.client;
    }

    toJSON() {
        return {
            client: this.client,
            filters: this.filters,
        }
    }

    // Determines whether a given model matches this subscription.
    qualify(model) {

        // Skip if no filters are set.
        if (!this.filters) {
            return false;
        }

        // Skip deleted or removed models.
        if (model.author === '[deleted]' || model.author === '[removed]') {
            return false;
        }

        /**
         * @property {ModelFilter} include
         * @property {ModelFilter} exclude
         */
        let include = this.filters.include;
        let exclude = this.filters.exclude;

        // Inclusion filters SHOULD validate if provided.
        if (include && ! include.test(model)) {
            return false;
        }

        // Exclusion filters SHOULD NOT validate if provided.
        if (exclude && exclude.test(model)) {
            return false;
        }

        // All filters passed.
        return true;
    }
}
