import Log from "../Utility/Log";
import uuid from 'uuid';
import {isString} from "lodash";
import nextTick from "async/nextTick";

/**
 * Wraps around a socket connection, providing an ID to identify it by.
 *
 * @property {WebSocket} ws
 */
export default class SocketClient {

    /**
     * @param {WebSocket} ws
     */
    constructor(ws, req) {
        this.ws = ws;
        this.id = uuid.v4();
    }

    /**
     * @returns {Object}
     */
    toJSON() {
        return {
            id: this.id,
            state: this.ws.readyState,
        }
    }

    /**
     *
     * @param data
     * @returns {*}
     */
    static format(data) {
        return typeof data === 'string'? data : JSON.stringify(data);
    }

    /**
     * Sends data to this client via it's socket connection.
     *
     * Will be encoded as JSON if not already a string.
     *
     * @param {Object|String} data
     * @param {Function} done
     */
    send(data, done) {
        if (this.ws.readyState === this.ws.OPEN) {
            this.ws.send(SocketClient.format(data), done);
        } else {
            nextTick(done);
        }
    }

    /**
     * @param message
     * @param done
     */
    error(message, done) {
        this.send({error: message}, done);
    }
}
