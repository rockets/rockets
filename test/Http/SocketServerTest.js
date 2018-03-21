class FakeClient {
  send(message) {
    this.last = message;
  }
}

describe('SocketServer', () => {

  describe('parseSubscription', () => {

    it('should accept valid JSON', () => {
      let s = new SocketServer();
      let client = new FakeClient();
      let parsed = s.parseSubscription(JSON.stringify({test: true}), client);

      assert.isUndefined(client.last);
      assert.deepEqual(parsed, {test: true});
    });

    it('should reject invalid JSON', () => {
      let s = new SocketServer();
      let client = new FakeClient();
      let parsed = s.parseSubscription(";", client);

      assert.deepEqual(client.last, {
        error: {
          message: "Could not parse subscription: Unexpected token ;"
        }
      });

      assert.isUndefined(parsed);
    });
  });


  describe('getChannel', () => {

    it('should accept a valid channel', () => {
      let s = new SocketServer();
      let client = new FakeClient();
      let data = {channel: 'posts'};
      let channel = MessageParser.getChannel(data, client);

      assert.equal(channel.name, 'posts');
      assert.isUndefined(client.last);
    });

    it('should reject an invalid channel', () => {
      let s = new SocketServer();
      let client = new FakeClient();
      let data = {channel: 'nope'};
      let channel = MessageParser.getChannel(data, client);

      assert.isUndefined(channel);

      assert.deepEqual(client.last, {
        error: {
          message: 'Unsupported channel',
          options: [
            'posts',
            'comments'
          ]
        }
      });
    });
  });

  describe('getFilters (deprecated)', () => {

    it('should produce post filter for posts channel', () => {
      let s = new SocketServer();
      let client = new FakeClient();
      let data = {channel: 'posts', filters: { nsfw: false }};
      let filters = MessageParser.getFilters(data, client);

      assert.deepEqual(filters.include.rules, {nsfw: { pass: [ false ], type: "boolean"}});
      assert.isUndefined(filters.exclude);
      assert.isUndefined(client.last);
    });

    it('should produce comment filter for comments channel', () => {
      let s = new SocketServer();
      let client = new FakeClient();
      let data = {channel: 'comments', filters: { root: false }};
      let filters = MessageParser.getFilters(data, client);

      assert.deepEqual(filters.include.rules, { root: { pass: [ false ], type: "boolean" }});
      assert.isUndefined(filters.exclude);
      assert.isUndefined(client.last);
    });

    it('should produce nothing filter for invalid channel', () => {
      let s = new SocketServer();
      let client = new FakeClient();
      let data = {channel: 'nope', filters: { something: false }};
      let filters = MessageParser.getFilters(data, client);

      assert.isUndefined(filters);
      assert.isUndefined(client.last);
    });
  });


  describe('getFilters', () => {

    it('should produce inclusion post filter for posts channel', () => {
      let s = new SocketServer();
      let client = new FakeClient();
      let data = {channel: 'posts', include: { nsfw: false }};
      let filters = MessageParser.getFilters(data, client);

      assert.deepEqual(filters.include.rules, { nsfw: { pass: [ false ], type: "boolean" }});
      assert.isUndefined(filters.exclude);
      assert.isUndefined(client.last);
    });

    it('should produce inclusion comment filter for comments channel', () => {
      let s = new SocketServer();
      let client = new FakeClient();
      let data = {channel: 'comments', include: { root: false }};
      let filters = MessageParser.getFilters(data, client);

      assert.deepEqual(filters.include.rules, { root: { pass: [ false ], type: "boolean" }});
      assert.isUndefined(filters.exclude);
      assert.isUndefined(client.last);
    });

    it('should produce exclusion post filter for posts channel', () => {
      let s = new SocketServer();
      let client = new FakeClient();
      let data = {channel: 'posts', exclude: { nsfw: false }};
      let filters = MessageParser.getFilters(data, client);

      assert.deepEqual(filters.exclude.rules, { nsfw: { pass: [ false ], type: "boolean" }});
      assert.isUndefined(filters.include);
      assert.isUndefined(client.last);
    });

    it('should produce exclusion comment filter for comments channel', () => {
      let s = new SocketServer();
      let client = new FakeClient();
      let data = {channel: 'comments', exclude: { root: false }};
      let filters = MessageParser.getFilters(data, client);

      assert.deepEqual(filters.exclude.rules, { root: { pass: [ false ], type: "boolean" }});
      assert.isUndefined(filters.include);
      assert.isUndefined(client.last);
    });

    it('should produce post filters for posts channel', () => {
      let s = new SocketServer();
      let client = new FakeClient();
      let data = {channel: 'posts', exclude: { nsfw: false }};
      let filters = MessageParser.getFilters(data, client);

      assert.deepEqual(filters.exclude.rules, { nsfw: { pass: [ false ], type: "boolean" }});
      assert.isUndefined(filters.include);
      assert.isUndefined(client.last);
    });

    it('should produce comment filters for comments channel', () => {
      let s = new SocketServer();
      let client = new FakeClient();
      let data = {channel: 'comments', exclude: { root: false }, include: { root: false }};
      let filters = MessageParser.getFilters(data, client);

      assert.deepEqual(filters.exclude.rules, { root: { pass: [ false ], type: "boolean" }});
      assert.deepEqual(filters.include.rules, { root: { pass: [ false ], type: "boolean" }});
      assert.isUndefined(client.last);
    });

    it('should produce nothing filter for invalid channel', () => {
      let s = new SocketServer();
      let client = new FakeClient();
      let data = {channel: 'nope', include: { something: false }};
      let filters = MessageParser.getFilters(data, client);

      assert.isUndefined(filters);
      assert.isUndefined(client.last);
    });

    it('should produce false filters for empty comment filters', () => {
      let s = new SocketServer();
      let client = new FakeClient();
      let data = {channel: 'comments', exclude: {}, include: {}};
      let filters = MessageParser.getFilters(data, client);

      assert.isUndefined(filters.include);
      assert.isUndefined(filters.exclude);
      assert.isUndefined(client.last);
    });

    it('should produce false filters for empty post filters', () => {
      let s = new SocketServer();
      let client = new FakeClient();
      let data = {channel: 'posts', exclude: {}, include: {}};
      let filters = MessageParser.getFilters(data, client);

      assert.isUndefined(filters.include);
      assert.isUndefined(filters.exclude);
      assert.isUndefined(client.last);
    });
  });

  describe('handleData', () => {

    it('should parse valid data', () => {
      let s = new SocketServer();
      let client = new FakeClient();
      let data = {channel: 'comments', filters: { root: false }};
      s.handleData(data, client);
      assert.isTrue('comments' in s.channels.channels);
    });

    it('should reject valid data', () => {
       let s = new SocketServer();
       let client = new FakeClient();
       let data = {channel: 'nope'};
       s.handleData(data, client);
       assert.isFalse('comments' in s.channels.channels);
       assert.isDefined(client.last);
     });
  });
});
