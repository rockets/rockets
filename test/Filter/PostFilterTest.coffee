describe 'PostFilter', ->

  model = {
    kind: 't3'
    data: {}
  }

  test = (key, value, expected) ->
    filter = new PostFilter({"#{key}": value})
    assert.equal(filter.validate(model), expected)

  fail = (key, value) ->
    test(key, value, false)

  pass = (key, value) ->
    test(key, value, true)


  match = (key, correct) ->
    it 'should pass for no provided values',        -> pass(key, [])
    it 'should pass for value that does match',     -> pass(key, correct)
    it 'should pass for many values with a match',  -> pass(key, [correct, 'no'])

    it 'should fail for value that does not match', -> fail(key, 'no')
    it 'should fail for many values with no match', -> fail(key, ['lol', 'no'])


  describe 'contains', ->

    model.data.selftext = 'This is a test'
    model.data.title    = 'string, 20'

    it 'should pass when empty array filter was specified',                 -> pass('contains', [])
    it 'should pass for single string match',                               -> pass('contains', 'test')
    it 'should pass for single pattern match',                              -> pass('contains', '\\w')
    it 'should pass for array of strings that contains a match',            -> pass('contains', ['test', 'nope'])
    it 'should pass for array of patterns that contains a match',           -> pass('contains', ['\\w', '\\d'])
    it 'should pass for a non-string pattern that does match',              -> pass('contains', 20)

    it 'should fail for single string that does not match',                 -> fail('contains', 'lol')
    it 'should fail for single pattern that does not match',                -> fail('contains', 'X')
    it 'should fail for array of strings that does not contain a match',    -> fail('contains', ['lol', 'nope'])
    it 'should fail for array of patterns that does not contain a match',   -> fail('contains', ['X', '\\w{100}'])
    it 'should fail for a non-string pattern that does not match',          -> fail('contains', 10)
    it 'should fail when a RegExp-breaking pattern is used',                -> fail('contains', ')')


  describe 'subreddit', ->
    match('subreddit', model.data.subreddit = 'aww')


  describe 'author', ->
    match('author', model.data.author = 'me')


  describe 'domain', ->
    match('domain', model.data.domain = 'redd.it')


  describe 'url', ->
    match('url', model.data.url = 'http://redd.it')


  bool = (filterKey, modelKey) ->

    _bool = (value, wanted, success) ->
      model = {kind: 't1', data: {"#{modelKey}": value}}
      filter = new PostFilter {"#{filterKey}": wanted}
      assert.equal(filter.validate(model), success)

    it "should pass when #{filterKey} and wanted #{filterKey}",         -> _bool(true, true, true)
    it "should fail when #{filterKey} but #{filterKey} not wanted",     -> _bool(true, false, false)
    it "should pass when not #{filterKey} but #{filterKey} not wanted", -> _bool(false, false, true)
    it "should fail when not #{filterKey} and wanted #{filterKey}",     -> _bool(false, true, false)


  describe 'nsfw', ->
    bool('nsfw', 'over_18')
