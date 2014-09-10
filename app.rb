require 'sinatra'
require 'mysql2'
require 'json'

require_relative 'lib/galera_health_checker'

configure do
  set :wsrep_state_dir, '/etc/mysql/wsrep'

  set(:hostname) { `hostname` }
end

configure :development do
  set :wsrep_state_dir, 'spec/data/3_node_cluster_synced'
  set :connection_settings, {
    host: 'localhost',
    username: 'root', 
    database: 'health_check'
  }
  set :hostname, 'dev.local'
end

configure :test do
  set :connection_settings, {
    host: 'localhost',
    username: 'root', 
    database: 'health_check'
  }
  set :hostname, 'test.local'
end

get '/' do
  checker = GaleraHealthChecker.new(
    wsrep_state_dir: settings.wsrep_state_dir,
    connection_settings: settings.connection_settings,
    hostname: settings.hostname
  )

  if checker.check
    [200, JSON.generate(checker.check_details)]
  else
    [503, JSON.generate(checker.check_details)]
  end
end
