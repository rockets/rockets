
# Export each file as a class, while also adding to the global app scope.
module.exports = -> @[name] = require("./#{path}") for name, path of {

  Subscription       : 'Channel/Subscription'
  ChannelRepository  : 'Channel/ChannelRepository'
  Channel            : 'Channel/Channel'

  Filter             : 'Filter/Filter'
  CommentFilter      : 'Filter/CommentFilter'
  PostFilter         : 'Filter/PostFilter'

  SocketServer       : 'Http/SocketServer'
  SocketClient       : 'Http/SocketClient'

  AccessToken        : 'Auth/AccessToken'
  OAuth2             : 'Auth/OAuth2'

  Worker             : 'Process/Worker'
  Master             : 'Process/Master'

  Queue              : 'Queue/Queue'
  # EmitQueue          : 'Queue/EmitQueue'
  ModelQueue         : 'Queue/ModelQueue'
  RateLimiter        : 'Queue/RateLimitQueue'

  Task               : 'Task/Task'
  CommentTask        : 'Task/CommentTask'
  PostTask           : 'Task/PostTask'

  Log                : 'Utility/Log'
}
