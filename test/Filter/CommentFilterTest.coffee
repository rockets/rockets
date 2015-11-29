describe 'CommentFilter', ->

  model = {
    kind: 't1'
    data: {}
  }

  test = (key, value, expected) ->
    filter = new CommentFilter({"#{key}": value})
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

    model.data.body = 'This is a test string, 20'

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
    model.data.subreddit = "aww"
    match('subreddit', 'aww')
    match('subreddit', 'AWW')


  describe 'author', ->
    model.data.author = 'me'
    match('author', 'me')
    match('author', 'ME')


  describe 'post', ->
    model.data.link_id = 'a'
    pass('post', 'a')
    pass('post', ['a'])
    pass('post', ['a', 'A'])
    fail('post', 'A')
    fail('post', ['A'])


  describe 'root', ->

    root = (parent_id, wanted, success) ->
      comment = {kind: 't1', data: {parent_id}}
      filter = new CommentFilter {root: wanted}
      assert.equal(filter.validate(comment), success)

    it 'should pass when root and wanted root',         -> root('t3_', true, true)
    it 'should fail when root but root not wanted',     -> root('t3_', false, false)
    it 'should pass when not root but root not wanted', -> root('t1_', false, true)
    it 'should fail when not root and wanted root',     -> root('t1_', true, false)
