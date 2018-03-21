import Queue from "./Queue";
import Subscription from "../Channels/Subscription";
import Log from "../Utility/Log";
import EmitQueue from "./EmitQueue";
import {each} from "async-es";

/**
 * @property {EmitQueue} emitter
 */
export default class ModelQueue extends Queue {

    constructor() {
        super();
        this.emitter = new EmitQueue();
    }

    concurrency() {
        return 4;
    }

    stats() {
        return {};
    }

    /**
     * @param {Subscription} subscription
     * @param {Model} model
     */
    emit(subscription, model) {
        if (subscription.qualify(model)) {
            this.emitter.emit(subscription.client, model);
        }
    }

    /**
     *
     * @param {Channel} channel
     * @param {Model} model
     */
    process(channel, model) {
        this.push((done) => {
            each(channel.subscriptions, (sub) => this.emit(sub, model), done);

        }, (error) => {
            if (error) {
                Log.error('Failed to process model', {channel, model, error});
            } else {
                Log.info('Successfully processed model', {model});
            }
        });
    }
}
