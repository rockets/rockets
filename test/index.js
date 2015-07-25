uuid = require('uuid');
chai = require('chai');

assert = chai.assert;

// Allows us to `require` .coffee files
require('coffee-script').register();

// Require all files in /src
require('../src')();
