import winston from "winston";
import {get} from "lodash";

const DEFAULT = new winston.Logger({
    transports: [
        new (winston.transports.File)({
            name:             'info',
            filename:         'logs/info.log',
            level:            'info',
            timestamp:        false,
            handleExceptions: false,
        }),
        new (winston.transports.File)({
            name:             'debug',
            filename:         'logs/debug.log',
            level:            'debug',
            timestamp:        false,
            handleExceptions: true,
        }),
        new winston.transports.Console({
            level: 'info',
            handleExceptions: false,
            json: false,
            colorize: true
        })
    ],
    exitOnError: false
});

const ERROR = new winston.Logger({
    transports: [
        new (winston.transports.File)({
            name:             'error',
            filename:         'logs/error.log',
            level:            'error',
            timestamp:        false,
            handleExceptions: true,
        }),
        new winston.transports.Console({
            level: 'error',
            handleExceptions: true,
            json: false,
            colorize: true
        })
    ],
    exitOnError: false
});

export default class Log {

    static getDate() {
        return new Date().toLocaleDateString();
    }

    static getTime() {
        return new Date().toTimeString();
    }

    static getUnix() {
        return Math.floor(Date.now() / 1000);
    }

    // Bundle log data into a consistent getFormattedData.
    static format(data) {
        return {
            date: Log.getDate(),
            time: Log.getTime(),
            unix: Log.getUnix(),
            meta: data,
        };
    }

    static info(message, meta, done) {
        DEFAULT.info(message, Log.format(meta), done);
    }

    static debug(message, meta, done) {
        DEFAULT.debug(message, Log.format(meta), done);
    }

    static error(error, done) {
        ERROR.error(get(error, 'message', 'Unknown Error'), {error}, done);
    }
}
