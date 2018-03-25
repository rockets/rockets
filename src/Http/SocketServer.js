/*
 * decaffeinate suggestions:
 * DS102: Remove unnecessary code created because of implicit returns
 * DS206: Consider reworking classes to avoid initClass
 * Full docs: https://github.com/decaffeinate/decaffeinate/blob/master/docs/suggestions.md
 */
/*
Socket server, responsible for:
  - Keeping track of client channels using a ChannelManager
  - Listening for new connections
  - Listening for dropped connections
*/

import * as ws from "ws";
import SocketClient from "./SocketClient";
import Log from "../Utility/Log";

/**
 * @property {Array} connected
 * @property {ws.Server} server
 */
export default class SocketServer {

    constructor() {
        this.server  = null;
        this.clients = {};
    }

    /**
     * @returns {Object}
     */
    stats() {
        return {};
    }

    /**
     * @returns {Array}
     */
    getClients() {
        return this.clients;
    }

    /**
     *
     */
    getServer() {
        return this.server;
    }

    /**
     *
     * @returns {{}}
     */
    getOptions() {
        return {
            port: process.env.PORT || 3210,
        }
    }

    /**
     * @param {Function} handler
     */
    listen(handler) {
        if (this.server) {
            throw new Error('Already listening!');
        }

        //
        this.server = new ws.Server(this.getOptions());

        //
        this.server.on('connection', (socket, request) => {
            let client = new SocketClient(socket, request);

            //
            this.clients[client.id] = client;

            //
            Log.info('socket.connect', {client});

            // Called when the connection to a client is lost.
            socket.on('close', () => {
                Log.info('socket.disconnect', {client});
            });

            // Called when an error occurs on the socket.
            socket.on('error', (error) => {
                Log.error('socket.error', {error, client});
            });

            //
            handler(client);
        });
    }
}
