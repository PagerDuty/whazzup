require 'logger'

require_relative 'config/production'
require_relative 'config/development'
require_relative 'config/test'

class Whazzup < Sinatra::Base
  configure do
    set :wsrep_state_dir, '/etc/mysql/wsrep'

    set(:hostname) { `hostname`.chomp }

    logger = ::Logger.new('log/check.log')
    logger.level = ::Logger::INFO
    set :check_logger, logger
    set :checkers, {}

    set :max_staleness, 10

    set :statsd_host, '127.0.0.1'
    set :statsd_port, 8125

    set :services, [:xdb]
  end
end
