require 'sinatra'
require 'mysql2'
require 'json'

configure do
  set :wsrep_state_dir, '/etc/mysql/wsrep'

  set(:hostname) { `hostname` }
end

configure :development do
  set :wsrep_state_dir, 'spec/data/3_node_cluster_synced'

  set :hostname, 'dev.local'
end

configure :test do
  set :hostname, 'test.local'
end

get '/' do
  state_info = {}

  state = File.read(File.join(settings.wsrep_state_dir, 'status')).strip
  size = File.read(File.join(settings.wsrep_state_dir, 'size')).strip.to_i

  state_info['wsrep_local_status'] = state
  state_info['cluster_size'] = size

  results = db_client.query("SELECT available FROM state WHERE host_name = '#{settings.hostname}'")
  health_check_state = results.first ? results.first['available'] : 0
  state_info['health_check.state'] = health_check_state

  up = case state
       when 'Synced'
         true
       when 'Donor'
         size == 2
       else
         false
       end

  up &&= health_check_state == 1

  state_info['available'] = up

  if up
    [200, JSON.generate(state_info)]
  else
    [503, JSON.generate(state_info)]
  end
end

def db_client
  @db_client ||= Mysql2::Client.new(
    host: 'localhost',
    username: 'root', 
    database: 'health_check'
  )
end
