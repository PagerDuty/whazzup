require 'sinatra'
require 'json'
require 'yaml'

require_relative 'lib/health_checker'

class Whazzup < Sinatra::Base
  configure do
    set :wsrep_state_dir, '/etc/mysql/wsrep'

    set(:hostname) { `hostname`.chomp }

    logger = Logger.new('log/check.log')
    logger.level = Logger::INFO
    set :check_logger, logger
    set :checkers, {}
  end

  configure :production do
    config = YAML.load_file ENV['WHAZZUP_CONFIG']
    set :connection_settings, {
      host: 'localhost',
      username: config['connection_settings']['username'],
      password: config['connection_settings']['password'],
      database: 'health_check'
    }

    set :max_staleness, 120 # 2 minutes
  end

  configure :development do
    set :wsrep_state_dir, 'spec/data/3_node_cluster_synced'
    set :connection_settings, {
      host: 'localhost',
      username: 'root', 
      database: 'health_check'
    }
    set :hostname, 'dev.local'

    set :max_staleness, 120 # 2 minutes

    logger = Logger.new(STDOUT)
    logger.level = Logger::DEBUG
    set :check_logger, logger
  end

  configure :test do
    set :connection_settings, {
      host: 'localhost',
      username: 'root', 
      database: 'health_check'
    }
    set :hostname, 'test.local'

    set :max_staleness, 120 # 2 minutes

    set :check_logger, Logger.new('/dev/null')
  end

  get '/xdb' do
    checker = xdb_checker

    if checker.check
      [200, JSON.generate(checker.check_details)]
    else
      [503, JSON.generate(checker.check_details)]
    end
  end

  def xdb_checker
    settings.checkers[:xdb] ||= begin
                                  require_relative 'lib/galera_health_checker'

                                  service_checker = GaleraHealthChecker.new(
                                    wsrep_state_dir: settings.wsrep_state_dir,
                                    connection_settings: settings.connection_settings,
                                    hostname: settings.hostname,
                                    logger: settings.check_logger
                                  )
                                  HealthChecker.new(
                                    service_checker: service_checker,
                                    max_staleness: settings.max_staleness,
                                    logger: settings.check_logger
                                  )
                                end
  end
end
