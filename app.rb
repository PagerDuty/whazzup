require 'sinatra'
require 'json'

require_relative 'lib/health_checker'
configure do
  set :wsrep_state_dir, '/etc/mysql/wsrep'

  set(:hostname) { `hostname` }

  set :check_logger, Logger.new('log/check.log')
  set :checkers, {}
end

configure :development do
  set :wsrep_state_dir, 'spec/data/3_node_cluster_synced'
  set :connection_settings, {
    host: 'localhost',
    username: 'root', 
    database: 'health_check'
  }
  set :hostname, 'dev.local'

  set :check_logger, Logger.new(STDOUT)
end

configure :test do
  set :connection_settings, {
    host: 'localhost',
    username: 'root', 
    database: 'health_check'
  }
  set :hostname, 'test.local'

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
                                  logger: settings.check_logger
                                )
                              end
end
