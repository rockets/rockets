require('dotenv').load();

cluster = require('cluster');
os      = require('os');
ws      = require('ws');
async   = require('async');
uuid    = require('uuid');
winston = require('winston');
restler = require('restler');

querystring = require('querystring');
http = require('http');

// Allows us to `require` .coffee files
require('coffee-script').register();

// Require all files in /src
require('./src')();

// Global log
log = new Log();

//
// process.on('uncaughtException', function (err) {
//   log.error({
//     message: 'uncaughtException',
//     err: err,
//   });
// });

// Create a new master process if master or create a worker if it's a fork.
cluster.isMaster ? new Master() : new Worker();
