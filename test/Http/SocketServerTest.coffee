

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
          message: "Unexpected token ;"
          name: "SyntaxError"
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
          name: 'ValueError',
          message: 'Unsupported channel'
      })


  describe 'getFilters', ->

    it 'should produce post filter for posts channel', ->
      s = new SocketServer()
      client = new FakeClient()
      data = {channel: 'posts', filters: { nsfw: false }}
      filter = s.getFilters(data, client)
      assert.deepEqual(filter.filters, { nsfw: [ false ] })
      assert.isUndefined(client.last)

    it 'should produce comment filter for comments channel', ->
      s = new SocketServer()
      client = new FakeClient()
      data = {channel: 'comments', filters: { root: false }}
      filter = s.getFilters(data, client)
      assert.deepEqual(filter.filters, { root: [ false ] })
      assert.isUndefined(client.last)

    it 'should produce nothing filter for invalid channel', ->
      s = new SocketServer()
      client = new FakeClient()
      data = {channel: 'nope', filters: { something: false }}
      filter = s.getFilters(data, client)
      assert.isUndefined(filter)
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
