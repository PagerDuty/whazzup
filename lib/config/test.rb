class Whazzup < Sinatra::Base
  configure :test do
    set :connection_settings, {
      host: 'localhost',
      username: 'root',
      database: 'health_check',
      reconnect: true
    }
    set :hostname, 'test.local'

    logger = Logger.new('/dev/null')
    logger.level = Logger::DEBUG
    set :check_logger, logger

    set :statsd_host, '0.0.0.0'
  end
end
