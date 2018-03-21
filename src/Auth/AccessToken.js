/**
 * Wrapper around a reddit OAuth2 access token response.
 *
 * See https://github.com/reddit/reddit/wiki/OAuth2
 */
export default class AccessToken {

    /**
     * Creates a new access token wrapper using decoded JSON data.
     */
    constructor(accessToken, ttl) {
        this.accessToken = accessToken;
        this.expiresAt = ttl + Math.floor(Date.now() / 1000);
    }

    getAccessToken() {
        return this.accessToken;
    }

    /**
     * Determines whether this access token has expired.
     *
     * Uses a 5 second safety period just to make sure we don't expire.
     */
    hasExpired() {
        return (this.expiresAt - Math.floor(Date.now() / 1000)) < 5;
    }
});
