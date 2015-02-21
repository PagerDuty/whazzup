require_relative 'routes/xdb'

class Whazzup < Sinatra::Base
  register Sinatra::Routing::Xdb
end
