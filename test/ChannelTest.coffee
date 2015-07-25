describe 'Channels', ->

  describe 'ChannelRepository', ->

    it 'should create a new channel successfully', ->
      repo = new ChannelRepository()
      channel = repo.createChannel('test')
      assert.instanceOf(channel, Channel)

    it 'should return a channel after its created', ->
      repo = new ChannelRepository()
      channel = repo.createChannel('test')
      assert.instanceOf(repo.getChannel('test'), Channel)

    it 'should not return a channel if it was not created', ->
      repo = new ChannelRepository()
      assert.isUndefined(repo.getChannel('test'))

    it 'should have knowledge that it has a stored channel after creation', ->
      repo = new ChannelRepository()
      channel = repo.createChannel('test')
      assert.isTrue('test' of repo.channels)

    it 'should not have knowledge of channel that was never created', ->
      repo = new ChannelRepository()
      assert.isFalse('test' of repo.channels)

    it 'should completely remove a given client from all channels', ->
      repo = new ChannelRepository()
      c1 = repo.createChannel('1')
      c2 = repo.createChannel('2')
      client = new SocketClient()
      sub = new Subscription(client, {})

      c1.addSubscription(sub)
      c2.addSubscription(sub)

      assert.isTrue('1' of repo.channels)
      assert.isTrue('2' of repo.channels)

      assert.isDefined(c1.subscriptions[client.id])
      assert.isDefined(c2.subscriptions[client.id])

      repo.removeClient(client)

      assert.isUndefined(c1.subscriptions[client.id])
      assert.isUndefined(c2.subscriptions[client.id])


  describe 'Channel', ->

    it 'should be constructed with a name', ->
      channel = new Channel('test')
      assert.equal(channel.name, 'test')

    it 'should be constructed with an empty subscription set', ->
      channel = new Channel()
      assert.isDefined(channel.subscriptions)
      assert.isObject(channel.subscriptions)
      assert.equal(Object.keys(channel.subscriptions).length, 0)

    it 'should successfully add subscription', ->
      client = new SocketClient()
      channel = new Channel()
      sub = new Subscription(client, {})
      channel.addSubscription(sub)
      assert.equal(channel.subscriptions[client.id], sub)

    it 'should successfully remove a client', ->
      client = new SocketClient()
      channel = new Channel()
      sub = new Subscription(client, {})

      channel.addSubscription(sub)
      assert.equal(channel.subscriptions[client.id], sub)

      channel.removeSubscription(client)
      assert.isUndefined(channel.subscriptions[client.id])
