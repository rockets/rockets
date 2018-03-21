import * as winston from "winston";

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
            name:             'error',
            filename:         'logs/error.log',
            level:            'error',
            timestamp:        false,
            handleExceptions: true,
        }),
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

    // Log arbitrary arguments to the info log
    static info(message, meta, done) {
        DEFAULT.log('info', message, Log.format(meta), done);
    }

    // Log arbitrary arguments to the error log
    static error(message, meta, done) {
        DEFAULT.log('error', message, Log.format(meta), done);
    }
}
