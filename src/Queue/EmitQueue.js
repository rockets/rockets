import Queue from "./Queue";
import Subscription from "../Channels/Subscription";
import EmitTask from "./Tasks/EmitTask";
import Log from "../Utility/Log";

export default class EmitQueue extends Queue {

    concurrency() {
        return 4;
    }

    stats() {
        return {};
    }

    /**
     *
     * @param {SocketClient} client
     * @param {Model} model
     */
    emit(client, model) {
        this.push((done) => client.send(model, done), (error) => {
            if (err) {
                Log.error('Failed to emit', {client, model, error});
            } else {
                Log.info('Successful emit', {client, model});
            }
        });
    }
}
