require 'sinatra/base'

module Sinatra
  module Config
    module Development
      def self.registered(app)
        app.configure :development do
          app.set :wsrep_state_dir, 'spec/data/3_node_cluster_synced'
          app.set :connection_settings, {
            host: 'localhost',
            username: 'root',
            database: 'health_check',
            reconnect: true
          }
          app.set :hostname, 'dev.local'

          logger = Logger.new(STDOUT)
          logger.level = Logger::DEBUG
          app.set :check_logger, logger
        end
      end
    end
  end
end
