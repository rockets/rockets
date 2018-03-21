import axios from "axios";
import RateLimiter from "./RateLimiter";
import OAuth2 from "../Auth/OAuth2";

export default class Client {

    constructor() {
        this.auth = new OAuth2();
        this.rate = new RateLimiter();
    }

    /**
     * @returns {Promise}
     */
    authenticate() {
        return new Promise((resolve, reject) => {
            let token = this.auth.getAccessToken();

            /**
             * No need to authenticate if we still have a valid token.
             */
            if (token && ! token.hasExpired()) {
                return resolve(token);
            }

            let parameters = {
                url: this.auth.getAccessTokenURL(),
                auth: {
                    username: this.auth.getClientId(),
                    password: this.auth.getClientPassword(),
                },
                data: {
                    grant_type: this.auth.getGrantType(),
                    username: this.auth.getUsername(),
                    password: this.auth.getPassword(),
                }
            };

            /**
             * Token is either not set or has expired, so get a new one.
             */
            this.client()
                .request(parameters)
                .then((response) => {
                    console.log('successful auth', {response});
                })
                .catch((error) => {
                    console.error('bad auth', {error});
                });
        });
    }
    //
    // getDefaultParameters() {
    //     return {
    //
    //     }
    // }

    client() {
        return axios.create({
            timeout: 2000,
        });
    }

    send(parameters) {
        return this.authenticate()
            .then(this.rate.limit)
            .then(() =>
                this.client()
                    .request(parameters)
                    .then(this.onResponse)
                    .catch(this.onError));
    }

    onResponse(response) {
        console.log('on response', {response});
    }

    onError(error) {
        console.log('on error', {error})
    }
}
