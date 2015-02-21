require 'sinatra/base'

module Sinatra
  module Config
    module Test
      def self.registered(app)
        app.configure :test do
          app.set :connection_settings, {
            host: 'localhost',
            username: 'root',
            database: 'health_check',
            reconnect: true
          }
          app.set :hostname, 'test.local'

          logger = Logger.new('/dev/null')
          logger.level = Logger::DEBUG
          app.set :check_logger, logger

          app.set :statsd_host, '0.0.0.0'
        end
      end
    end
  end
end
