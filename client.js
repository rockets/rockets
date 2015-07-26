// This is a demo client to demonstrate how it could be used.
// Uses https://github.com/websockets/ws.

var WebSocket = require('ws');

// Create a new socket connection.
var socket = new WebSocket("ws://rockets.cc:3210");

// Called when the socket connection is ready for use.
socket.on('open', function () {
  socket.send(JSON.stringify({
      channel: 'comments',
      filters: {
          contains: [
              '\\bLOL\\b',
              'haha',
          ],
      },
  }));
});

// Called when the socket connection is closed.
socket.on('close', function () {
  console.log('Disconnected');
});

// Called when the socket encounters an error.
socket.on('error', function (err) {
  console.error(err);
});

// Called when a new message is received from the command center.
socket.on('message', function (data) {

  // The message will be JSON data so you will need to parse it first.
  var data = JSON.parse(data).data;

  var date = new Date(data.created_utc * 1000);
  var user = 'u/' + data.author;
  var subr = 'r/' + data.subreddit;
  var text = data.body.replace(/\s/g, ' ');

  var formatted = date + ": by " + user + ' in ' + subr + ': ' + text;
  var maxLength = 120;

  // Truncate if required so that it fits nicely in a terminal window.
  if (message.length > maxLength) {
      message = message.substring(0, maxLength - 3) + '...';
  }

  console.log(message);
});
