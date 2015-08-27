require('dotenv').load();

cluster = require('cluster');
os      = require('os');
ws      = require('ws');
async   = require('async');
request = require('request');
uuid    = require('uuid');
bunyan  = require('bunyan');

// Not sure what this does but it's worth a shot.
request.debug = true;

// Allows us to `require` .coffee files
require('coffee-script').register();

// Require all files in /src
require('./src')();

// Global log
log = new Log();

// Create a new master process if master or create a worker if it's a fork.
cluster.isMaster ? new Master() : new Worker();
