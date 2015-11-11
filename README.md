![Rockets](header.gif) [![Author](http://img.shields.io/badge/author-u%2Frtheunissen-336699.svg?style=flat-square)](https://reddit.com/u/rtheunissen) [![Support](https://img.shields.io/badge/support-donate-399c99.svg?style=flat-square)](https://plasso.co/rudolf.theunissen@gmail.com) [![Stability](https://img.shields.io/badge/status-pending-777777.svg?style=flat-square)]()
---

**Mission**
>Provide a way to stream new content on reddit.com without using the API.

Many reddit bots rely on monitoring new content, constantly sending requests to keep up. Unfortunately this means that bots can't use their precious rate-limit tokens to then *do something* with that content.

*Rockets* allows you to subscribe to a `channel`, with the ability to specify content `filters`. All you need to do is open a web socket connection to the command center at `ws://rockets.cc:3210` and transmit your subscription.

You will receive JSON models exactly as they appear in reddit listings, ie. with `kind` and `data` keys. These will be sent one at a time, but are not guaranteed to be in perfect chronological order due to the level of concurrency on the server.

#### Demo

See [rockets-demo](https://github.com/rtheunissen/rockets-demo).

