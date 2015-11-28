

class FakeClient
  send: (message) ->
    @last = message
    return

describe 'SocketServer', ->

  describe 'parseMessage', ->

    it 'should accept valid JSON', ->
      s = new SocketServer()
      client = new FakeClient()
      parsed = s.parseMessage(JSON.stringify(test: true), client)
      assert.isUndefined(client.last)
      assert.deepEqual(parsed, test: true)

    it 'should reject invalid JSON', ->
      s = new SocketServer()
      client = new FakeClient()
      parsed = s.parseMessage(";", client)
      assert.deepEqual(client.last, {
        error:
          message: "Could not parse subscription: Unexpected token ;"
      })
      assert.isUndefined(parsed)


  describe 'getChannel', ->

    it 'should accept a valid channel', ->
      s = new SocketServer()
      client = new FakeClient()
      data = {channel: 'posts'}
      channel = s.getChannel(data, client)
      assert.equal(channel.name, 'posts')
      assert.isUndefined(client.last)

    it 'should reject an invalid channel', ->
      s = new SocketServer()
      client = new FakeClient()
      data = {channel: 'nope'}
      channel = s.getChannel(data, client)
      assert.isUndefined(channel)
      assert.deepEqual(client.last, {
        error:
          message: 'Unsupported channel'
          options: [
            'posts',
            'comments'
          ]
      })


  describe 'getFilters (deprecated)', ->

    it 'should produce post filter for posts channel', ->
      s = new SocketServer()
      client = new FakeClient()
      data = {channel: 'posts', filters: { nsfw: false }}
      filters = s.getFilters(data, client)
      assert.deepEqual(filters.include.rules, { nsfw: [ false ] })
      assert.isUndefined(filters.exclude)
      assert.isUndefined(client.last)

    it 'should produce comment filter for comments channel', ->
      s = new SocketServer()
      client = new FakeClient()
      data = {channel: 'comments', filters: { root: false }}
      filters = s.getFilters(data, client)
      assert.deepEqual(filters.include.rules, { root: [ false ] })
      assert.isUndefined(filters.exclude)
      assert.isUndefined(client.last)

    it 'should produce nothing filter for invalid channel', ->
      s = new SocketServer()
      client = new FakeClient()
      data = {channel: 'nope', filters: { something: false }}
      filters = s.getFilters(data, client)
      assert.isUndefined(filters)
      assert.isUndefined(client.last)


  describe 'getFilters', ->

    it 'should produce inclusion post filter for posts channel', ->
      s = new SocketServer()
      client = new FakeClient()
      data = {channel: 'posts', include: { nsfw: false }}
      filters = s.getFilters(data, client)
      assert.deepEqual(filters.include.rules, { nsfw: [ false ] })
      assert.isUndefined(filters.exclude)
      assert.isUndefined(client.last)

    it 'should produce inclusion comment filter for comments channel', ->
      s = new SocketServer()
      client = new FakeClient()
      data = {channel: 'comments', include: { root: false }}
      filters = s.getFilters(data, client)
      assert.deepEqual(filters.include.rules, { root: [ false ] })
      assert.isUndefined(filters.exclude)
      assert.isUndefined(client.last)

    it 'should produce exclusion post filter for posts channel', ->
      s = new SocketServer()
      client = new FakeClient()
      data = {channel: 'posts', exclude: { nsfw: false }}
      filters = s.getFilters(data, client)
      assert.deepEqual(filters.exclude.rules, { nsfw: [ false ] })
      assert.isUndefined(filters.include)
      assert.isUndefined(client.last)

    it 'should produce exclusion comment filter for comments channel', ->
      s = new SocketServer()
      client = new FakeClient()
      data = {channel: 'comments', exclude: { root: false }}
      filters = s.getFilters(data, client)
      assert.deepEqual(filters.exclude.rules, { root: [ false ] })
      assert.isUndefined(filters.include)
      assert.isUndefined(client.last)

    it 'should produce post filters for posts channel', ->
      s = new SocketServer()
      client = new FakeClient()
      data = {channel: 'posts', exclude: { nsfw: false }}
      filters = s.getFilters(data, client)
      assert.deepEqual(filters.exclude.rules, { nsfw: [ false ] })
      assert.isUndefined(filters.include)
      assert.isUndefined(client.last)

    it 'should produce comment filters for comments channel', ->
      s = new SocketServer()
      client = new FakeClient()
      data = {channel: 'comments', exclude: { root: false }, include: { root: false }}
      filters = s.getFilters(data, client)
      assert.deepEqual(filters.exclude.rules, { root: [ false ] })
      assert.deepEqual(filters.include.rules, { root: [ false ] })
      assert.isUndefined(client.last)

    it 'should produce nothing filter for invalid channel', ->
      s = new SocketServer()
      client = new FakeClient()
      data = {channel: 'nope', include: { something: false }}
      filters = s.getFilters(data, client)
      assert.isUndefined(filters)
      assert.isUndefined(client.last)

    it 'should produce false filters for empty comment filters', ->
      s = new SocketServer()
      client = new FakeClient()
      data = {channel: 'comments', exclude: {}, include: {}}
      filters = s.getFilters(data, client)
      assert.isUndefined(filters.include)
      assert.isUndefined(filters.exclude)
      assert.isUndefined(client.last)

    it 'should produce false filters for empty post filters', ->
      s = new SocketServer()
      client = new FakeClient()
      data = {channel: 'posts', exclude: {}, include: {}}
      filters = s.getFilters(data, client)
      assert.isUndefined(filters.include)
      assert.isUndefined(filters.exclude)
      assert.isUndefined(client.last)

  describe 'handleData', ->


    it 'should parse valid data', ->
      s = new SocketServer()
      client = new FakeClient()
      data = {channel: 'comments', filters: { root: false }}
      s.handleData(data, client)
      assert.isTrue('comments' of s.channels.channels)

     it 'should reject valid data', ->
       s = new SocketServer()
       client = new FakeClient()
       data = {channel: 'nope'}
       s.handleData(data, client)
       assert.isFalse('comments' of s.channels.channels)
       assert.isDefined(client.last)
