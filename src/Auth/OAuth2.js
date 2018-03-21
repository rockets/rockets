/**
 * @property {AccessToken} token
 */
export default class OAuth2 {

    /**
     * @property {AccessToken} token
     */
    constructor() {
        this.token = null;
    }

    /**
     * @returns {AccessToken}
     */
    getAccessToken() {
        return this.token;
    }

    /**
     * @property {AccessToken} token
     */
    setAccessToken(token) {
        this.token = token;
    }

    getAuthenticationHeaders() {
        return {
            'User-Agent': this.getUserAgent(),
        };
    }

    //       username: process.env.CLIENT_ID,
//       password: process.env.CLIENT_SECRET,
//       data: {
//         grant_type: 'password',
//         username: process.env.USERNAME,
//         password: process.env.PASSWORD
//       },

    getClientId() {
        return _.get(process.env, 'CLIENT_ID');
    }

    getClientPassword() {
        return _.get(process.env, 'CLIENT_SECRET');
    }

    getGrantType() {
        return 'password';
    }

    getUsername() {
        return _.get(process.env, 'USERNAME');
    }

    getPassword() {
        return _.get(process.env, 'PASSWORD');
    }

    getUserAgent() {
        return _.get(process.env, 'USER_AGENT');
    }

    getAccessTokenURL() {
        return 'https://www.reddit.com/api/v1/access_token';
    }
}
//
// let OAuth2;
// module.exports = (OAuth2 = class OAuth2 {
//
//   constructor() {
//     this.rate = new RateLimiter();
//     this.token = null;
//   }
//
//
//   // Wraps around a request to act as a fallback timeout in case something goes
//   // wrong with the request resulting in the callback not being called.
//   fallback(callback, make) {
//     log.info('request.make');
//
//     // Make the request, providing a handle to abort with later.
//     const request = make();
//
//     const cancel = function() {
//       log.info('request.abort.fallback');
//       return request.abort();
//     };
//
//     return setTimeout(cancel, (10 * 1000));  // 10s
//   }
//
//
//   // Wraps authentication around a callback which expects an access token.
//   authenticate(callback) {
//
//     // Use the current token if it's still valid.
//     let timeout;
//     if (this.token && !this.token.hasExpired()) {
//       return callback(this.token);
//     }
//
//     const parameters = {
//       headers: {
//         'User-Agent': process.env.USER_AGENT
//       },
//       username: process.env.CLIENT_ID,
//       password: process.env.CLIENT_SECRET,
//       data: {
//         grant_type: 'password',
//         username: process.env.USERNAME,
//         password: process.env.PASSWORD
//       },
//
//       // 5s request timeout
//       timeout: 5000
//     };
//
//     // Wrap a fallback timeout in case something goes wrong internally.
//     return timeout = this.fallback(callback, () => {
//       return restler.post('https://www.reddit.com/api/v1/access_token', parameters)
//
//         // Called when an access token request is successful.
//         .on('success', (data, response) => {
//           return this.token = new AccessToken(data);
//       }).on('timeout', function(ms) {
//           log.error('Access token request timeout');
//           clearTimeout(timeout);
//           return callback();
//         }).on('error', (err, response) =>
//           log.error('Unexpected error during access token request', {
//             status: (response != null ? response.statusCode : undefined),
//             error: err
//           }
//           )
//         ).on('fail', (data, response) =>
//           log.error('Unexpected status code for access token request',
//             {status: (response != null ? response.statusCode : undefined)})
//         ).on('complete', (result, response) => {
//           clearTimeout(timeout);
//           return callback(this.token);
//       });
//     });
//   }
//
//
//   // Requests models from reddit.com using given request parameters.
//   // Passes models to a handler or `false` if the request was unsuccessful.
//   models(parameters, handler) {
//
//     // Initialise blank headers
//     parameters.headers = parameters.headers || {};
//
//     // Wrap token authentication around the request
//     return this.authenticate(token => {
//
//       // Don't make the request if the token is not valid
//       if (!token) {
//         return handler();
//       }
//
//       // 5s request timeout.
//       parameters.timeout = 5000;
//
//       // Disable connection pooling.
//       parameters.agent = false;
//
//       // User agent should be the only header we need to set for a API requests.
//       parameters.headers['User-Agent'] = process.env.USER_AGENT;
//
//       // Set the OAuth2 access token.
//       parameters.accessToken = this.token.token;
//
//       // Schedule a rate limited request task.
//       return this.rate.delay(() => {
//
//         // Wrap request in a 10 second fallback timeout in case something goes
//         // wrong internally (this should never happen though).
//         let timeout;
//         return timeout = this.fallback(handler, () => {
//           return restler.request(parameters.url, parameters)
//
//             // Called when the request was successful.
//             .on('success', function(data, response) {
//               try {
//                 const parsed = JSON.parse(data);
//
//                 // Make sure that the parsed JSON is also in the expected getFormattedData,
//                 // which should be a standard reddit 'Listing'.
//                 if (!parsed.data || !('children' in parsed.data)) {
//                   return handler();
//                 }
//
//                 // Reddit doesn't always send results in the right order.
//                 // Sort the models by ascending ID, ie. from oldest to newest.
//                 const models = parsed.data.children.sort((a, b) => parseInt(a.data.id, 36) - parseInt(b.data.id, 36));
//
//                 return handler(models);
//
//               } catch (exception) {
//                 return handler();
//               }
//           }).on('error', function(err, response) {
//               log.error('Unexpected request error', {
//                 status: (response != null ? response.statusCode : undefined),
//                 error: err
//               }
//               );
//
//               return handler();
//               }).on('timeout', function(ms) {
//               clearTimeout(timeout);
//               return log.error('Request timed out',
//                 {parameters});
//             }).on('fail', function(data, response) {
//               log.error('Unexpected status code', {
//                 status: (response != null ? response.statusCode : undefined),
//                 parameters
//               }
//               );
//
//               return handler();
//               }).on('complete', (result, response) => {
//               clearTimeout(timeout);
//
//               // Set the rate limit allowance using the reddit ratelimit headers.
//               // See https://www.reddit.com/1yxrp7
//               if (response) {
//                 return this.setRateLimit(response);
//               }
//           });
//         });
//       });
//     });
//   }
//
//
//   // Attempts to set the allowed rate limit using a response
//   setRateLimit(response) {
//     if (response != null ? response.headers : undefined) {
//       const messages = response.headers['x-ratelimit-remaining'];
//       const seconds  = response.headers['x-ratelimit-reset'];
//
//       return this.rate.setRate(messages, seconds);
//     }
//   }
// });
