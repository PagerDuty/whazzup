require 'sinatra/base'

module Sinatra
  module Config
    module Default
      def self.registered(app)
        app.configure do
          app.set :wsrep_state_dir, '/etc/mysql/wsrep'

          app.set(:hostname) { `hostname`.chomp }

          logger = ::Logger.new('log/check.log')
          logger.level = ::Logger::INFO
          app.set :check_logger, logger
          app.set :checkers, {}

          app.set :max_staleness, 10

          app.set :statsd_host, '127.0.0.1'
          app.set :statsd_port, 8125

          app.set :services, [:xdb]
        end
      end
    end
  end
end
