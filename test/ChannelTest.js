describe('Channels', () => {

  describe('ChannelManager', () => {

    it('should create a new channel successfully', () => {
      let repo = new ChannelManager();
      let channel = repo.createChannel('test');
      assert.instanceOf(channel, Channel);
    });

    it('should return a channel after its created', () => {
      let repo = new ChannelManager();
      let channel = repo.createChannel('test');
      assert.instanceOf(MessageParser.getChannel('test'), Channel);
    });

    it('should not return a channel if it was not created', () => {
      let repo = new ChannelManager();
      assert.isUndefined(MessageParser.getChannel('test'));
    });

    it('should have knowledge that it has a stored channel after creation', () => {
      let repo = new ChannelManager();
      let channel = repo.createChannel('test');
      assert.isTrue('test' in repo.channels);
    });

    it('should not have knowledge of channel that was never created', () => {
      let repo = new ChannelManager();
      assert.isFalse('test' in repo.channels);
    });

    it('should completely remove a given client from all channels', () => {
      let repo = new ChannelManager();
      let c1 = repo.createChannel('1');
      let c2 = repo.createChannel('2');
      let client = new SocketClient();
      let sub = new Subscription(client, {});

      c1.addSubscription(sub);
      c2.addSubscription(sub);

      assert.isTrue('1' in repo.channels);
      assert.isTrue('2' in repo.channels);

      assert.isDefined(c1.subscriptions[client.id]);
      assert.isDefined(c2.subscriptions[client.id]);

      repo.removeClient(client);

      assert.isUndefined(c1.subscriptions[client.id]);
      assert.isUndefined(c2.subscriptions[client.id]);
    });
  });


  describe('Channel', () => {

    it('should be letructed with a name', () => {
      let channel = new Channel('test');
      assert.equal(channel.name, 'test');
    });

    it('should be letructed with an empty subscription set', () => {
      let channel = new Channel();
      assert.isDefined(channel.subscriptions);
      assert.isObject(channel.subscriptions);
      assert.equal(Object.keys(channel.subscriptions).length, 0);
    });

    it('should successfully add subscription', () => {
      let client = new SocketClient();
      let channel = new Channel();
      let sub = new Subscription(client, {});
      channel.addSubscription(sub);
      assert.equal(channel.subscriptions[client.id], sub);
    });

    it('should successfully remove a client', () => {
      let client = new SocketClient();
      let channel = new Channel();
      let sub = new Subscription(client, {});

      channel.addSubscription(sub);
      assert.equal(channel.subscriptions[client.id], sub);

      channel.removeSubscription(client);
      assert.isUndefined(channel.subscriptions[client.id]);
    });
  });
});
