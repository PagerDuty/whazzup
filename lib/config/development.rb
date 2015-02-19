class Whazzup < Sinatra::Base
  configure :development do
    set :wsrep_state_dir, 'spec/data/3_node_cluster_synced'
    set :connection_settings, {
      host: 'localhost',
      username: 'root',
      database: 'health_check',
      reconnect: true
    }
    set :hostname, 'dev.local'

    logger = Logger.new(STDOUT)
    logger.level = Logger::DEBUG
    set :check_logger, logger
  end
end
