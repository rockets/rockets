import Log from "../Utility/Log";
import Post from "../Models/Post";
import Comment from "../Models/Comment";
import PostFilter from "../Filters/PostFilter";
import CommentFilter from "../Filters/CommentFilter";

/**
 * @property {Object} subscriptions
 */
class Channel {

    constructor(name) {
        this.name = name;
        this.subscriptions = {};
    }

    toJSON() {
        return {
            name: this.name,
        }
    }

    stats() {

    }

    /**
     * @param {SocketClient} client
     */
    release(client) {
        if (client.id in this.subscriptions) {
            Log.info('subscriptions.release', {client});

            //
            delete this.subscriptions[client.id];
        }
    }

    /**
     * Adds a subscription to this channel.
     *
     * @param {Subscription} subscription
     */
    register(subscription) {
        Log.info('subscriptions.register', {subscription});

        let client = subscription.client;

        // Register a listener to remove the subscription when disconnected.
        if (!(client.id in this.subscriptions)) {
            client.ws.on('close', () => this.release(client));
        }

        this.subscriptions[client.id] = subscription;
    }
}

const NAME_POSTS = 'posts';

const NAME_COMMENTS = 'comments';

/**
 * @type {Channel}
 */
const posts = new Channel(NAME_POSTS);

/**
 * @type {Channel}
 */
const comments = new Channel(NAME_COMMENTS);

/**
 * @param {Model} model
 *
 * @returns {Channel|undefined}
 */
Channel.forModel = function(model) {
    if (model instanceof Comment) {
        return comments;
    }

    if (model instanceof Post) {
        return posts;
    }
};

/**
 * @param name
 *
 * @returns {Channel}
 */
Channel.fromName = function(name) {
    switch (name) {
        case NAME_COMMENTS:
            return comments;

        case NAME_POSTS:
            return posts;
    }
};

/**
 *
 * @param {Channel} channel
 *
 * @returns {*}
 */
Channel.getFilter = function(channel) {
    if (channel === posts) {
        return PostFilter;
    }

    if (channel === comments) {
        return CommentFilter;
    }
};

export default Channel;
