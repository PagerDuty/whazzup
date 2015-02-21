require_relative 'helpers/statsd_helper'
require_relative 'helpers/xdb_helper'

class Whazzup < Sinatra::Base
  helpers Sinatra::Helpers::StatsdHelper
  helpers Sinatra::Helpers::Xdb
end
