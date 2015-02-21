require 'logger'

require_relative 'config/default'
require_relative 'config/production'
require_relative 'config/development'
require_relative 'config/test'

class Whazzup < Sinatra::Base
  register Sinatra::Config::Default
  register Sinatra::Config::Production
  register Sinatra::Config::Development
  register Sinatra::Config::Test
end
