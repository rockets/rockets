import Log from "../Utility/Log";
import Channel from "../Channels/Channel";
import Subscription from "../Channels/Subscription";
import {get} from "lodash";

const MAX_MESSAGE_SIZE = 1000 * 1000; // 1 Mb

export default class MessageParser {

    // Guards against massive JSON messages.
    isTooLarge(message) {
        return Buffer.byteLength(message, 'utf8') > MAX_MESSAGE_SIZE;
    }

    /**
     *
     * @param message
     * @param client
     */
    parseMessage(message, client) {
        Log.info('socket.message', {data: message, client: client});

        //
        if (this.isTooLarge(message)) {
            client.error({message: 'Payload too large!'});
            return;
        }

        try {
            return JSON.parse(message);
        } catch (e) {
            client.error({message: 'Failed to parse subscription'});
        }
    }

    // Determines and returns and appropriate filter for the given data.
    getFilters(data, client, filter) {
        let include = get(data, 'include');
        let exclude = get(data, 'exclude');

        return {
            include: include ? new filter(include) : null,
            exclude: exclude ? new filter(exclude) : null,
        }
    }

    /**
     *
     * @param {Object} data
     * @param {SocketClient} client
     *
     * @returns {Channel}
     */
    getChannel(data, client) {
        let channel = Channel.fromName(data.channel);

        if (channel) {
            return channel;
        }

        client.error({message: 'Unsupported channel'});
    }

    /**
     *
     * @param {SocketClient} client
     * @param message
     */
    static parse(client, message) {
        let data = this.parseMessage(message);

        //
        if (data) {
            let channel = this.getChannel(data, client);

            //
            if (channel) {
                let filters = this.getFilters(data, client, Channel.getFilter(channel));

                //
                if (filters) {
                    channel.register(new Subscription(client, filters));
                }
            }
        }
    }
}
