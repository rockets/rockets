/*
 * decaffeinate suggestions:
 * DS102: Remove unnecessary code created because of implicit returns
 * DS202: Simplify dynamic range loops
 * Full docs: https://github.com/decaffeinate/decaffeinate/blob/master/docs/suggestions.md
 */
/*
Master process, responsible for:
  - Forking socket server workers
  - Initiating request tasks
*/
import CommentTask from "../Requests/CommentRequest";
import PostTask from "../Requests/PostRequest";
import HttpClient from "../Http/HttpClient";
import Log from "../Utility/Log";
import SocketServer from "../Http/SocketServer";
import ModelQueue from "../Queue/ModelQueue";
import {forever} from "async-es";
import Channel from "../Channels/Channel";
import MessageParser from "../Parsers/MessageParser";


/**
 * @type {number}
 */
const POST_BACKLOG_MOD = 20;

// This is the requester.
export default class Master {

    constructor() {
        this.loops    = 1;
        this.started  = Date.now();

        this.server   = new SocketServer();
        this.queue    = new ModelQueue();
        this.parser   = new MessageParser();

        this.http     = new HttpClient();
        this.comments = new CommentTask(this.http);
        this.posts    = new PostTask(this.http);
    }

    /**
     * Broadcasts all given models to their respective channels. This method
     * returns immediately, as all broadcasting should be handled asynchronously
     * without blocking whatever calls this. If a broadcast should fail, all
     * processes should still continue.
     *
     * @param {Array} models
     */
    broadcast(models) {

        /**
         * @property {Model} model
         */
        for (model of models)  {
            let channel = Channel.forModel(model);

            if (channel) {
                this.queue.process(channel, model);
            }
        }
    }

    /**
     *
     *
     * @returns {Promise}
     */
    getPosts() {
        if (this.loops % POST_BACKLOG_MOD) {
            return this
                .posts
                .reversed()
                .then((models) => this.broadcast(models));
        }

        //
        return this
            .posts
            .forward()
            .then((models) => this.broadcast(models));
    }

    /**
     * @returns {Promise}
     */
    getComments() {
        return this
            .comments
            .reversed()
            .then((models) => this.broadcast(models));
    }

    /**
     * @returns {Promise}
     */
    stats() {
        return new Promise((resolve, reject) => {
            let stats = {
                uptime:     Date.now() - this.started,
                loops:      this.loops,
                comments:   this.comments.stats(),
                posts:      this.posts.stats(),
                server:     this.server.stats(),
                queue:      this.queue.stats(),
            };

            Log.info('stats', stats, (error) => {
                if (error) {
                    reject(error);
                } else {
                    resolve();
                }
            });
        });
    }

    listen() {
        this.server.listen((client) => {

            //
            Log.info('socket.connect', {client});

            //
            client.ws.on('message', (message) => {
                MessageParser.parse(client, message);
            });

            // Called when the connection to a client is lost.
            client.ws.on('close', () => {
                Log.info('socket.disconnect', {client});
            });

            // Called when an error occurs on the socket.
            client.ws.on('error', (error) => {
                Log.error('socket.error', {error, client});
            });
        });
    }

    /**
     * @param error
     */
    onError(error) {
        Log.error(error.message, {error});
    }

    // Returns an array of model fetch tasks to run
    start() {

        /**
         * Start the socket server.
         */
        this.listen();

        /**
         * Start the request loop.
         */
        forever((next) => {
            return this
                .stats()
                .then(this.getComments)
                .then(this.getPosts)
                .catch(this.onError)
                .then(next);
        });
    }
}
