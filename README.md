![Rockets](header.gif) [![Author](http://img.shields.io/badge/author-u%2Frtheunissen-336699.svg?style=flat-square)](https://reddit.com/u/rtheunissen) [![Support](https://img.shields.io/badge/support-donate-399c99.svg?style=flat-square)](https://plasso.co/rudolf.theunissen@gmail.com) [![Stability](https://img.shields.io/badge/stability-beta-fe7b63.svg?style=flat-square)]()
---

**Mission**
>Provide a way for bots to continuously monitor new content on reddit.com without using the API.

Many reddit bots rely on monitoring new content, constantly sending requests to keep up. Unfortunately this means that bots can't use their precious rate-limit tokens to then *do something* with that content.

*Rockets* allows you to subscribe to a `channel`, with the ability to specify content `filters`. All you need to do is open a web socket connection to the command center at `ws://rockets.cc:3210` and transmit your subscription.

You will receive JSON models exactly as they appear in reddit listings, ie. with `kind` and `data` keys. These will be sent one at a time, but are not guaranteed to be in perfect chronological order due to the level of concurrency on the server.

## Subscriptions

Subscriptions are sent as JSON in the following format:

```js
{
    "channel": "",
    "filters": {

    }
}
```
## Channels

- `comments`
- `posts`

## Filters

All filters can be provided as either a single value or an array of values.
A filter is considered a match if any of the values match the corresponding value in the model.

#### Comments

| Key       | Type            | Description                                                      |
|-----------|-----------------|------------------------------------------------------------------|
| contains  | string (regex)  | Comment body (markdown), case-insensitive                        |
| subreddit | string          | Subreddit in which the comment was made, eg. "subreddit"         |
| author    | string          | The user who made the comment, eg. "username"                    |
| post      | string          | Comments that are replies to a specific post, eg. "t3_abcd"      |
| root      | boolean         | Comments that are not replies to other comments                  |

#### Posts

| Key       | Type            | Description                                                      |
|-----------|-----------------|------------------------------------------------------------------|
| contains  | string (regex)  | Link title and selftext (markdown), case-insensitive             |
| subreddit | string          | Subreddit in which the post was made, eg. "subreddit"            |
| author    | string          | The user who made the post, eg. "username"                       |
| domain    | string          | Link's domain, or "self.subreddit" if it's a selfpost            |
| url       | string          | Link's URL, or the post's permalink if it's a selfpost           |
| nsfw      | boolean         | Flagged NSFW at the time of creation                             |


## Example

```js
{
    "channel": "comments",
    "filters": {

        "subreddit": [
          "space",
          "spacex",
          "science"
        ],

        "contains": [
          "mars",
          "rockets",
          "\\bion\\b"
        ]
    }
}
```

## Limitations

#### Dropped connections

The server will drop all connections when being updated or restarted, which can't be avoided. Make sure that your client
will attempt to reconnect automatically when a connection is dropped. Updates will be posted to /r/redditdev in the event
of unexpected downtime.

#### Latency

Even though the command center is in low reddit orbit, there will always be some delay between a model's creation and its broadcast. Most of the time this delay will only be a few seconds, but could be several minutes in some cases. This occurs when reddit.com goes down, or during very busy periods. The command center will catch up again when things are back to normal or when busy periods subside. Data will not be lost during this time.

#### Bandwidth

A single model is roughly 1kb of JSON. The command center receives an average of 30 models per second. This works out to about 2.6GB per day, per unfiltered connection. With a limit of 8TB downstream traffic per month, this equates to a maximum of roughly 100 concurrent unfiltered connections.

#### Subscriptions

You are only allowed one subscription per connection per channel, where new subscriptions replace previous ones.
It's possible that some unwanted models may still be received after a subscription has been replaced, so you should
open a new connection when you need a strict boundary between subscriptions.

## Support

There are a few ways to resupply and assist the CC:

- Use filters to avoid receiving unwanted data.
- Donate a few dollars to help cover server costs.
- Sponsor this app if you have a lot of bandwidth at your disposal.

## Credits

Illustrations by Ken Samonte.
