require 'sinatra'

configure do
  set :wsrep_state_dir, '/etc/mysql/wsrep'
end

configure :development do
  set :wsrep_state_dir, 'spec/data/3_node_cluster_synced'
end

get '/' do
  state = File.read(File.join(settings.wsrep_state_dir, 'status')).strip
  size = File.read(File.join(settings.wsrep_state_dir, 'size')).strip.to_i

  up = case state
       when 'Synced'
         true
       when 'Donor'
         size == 2
       else
         false
       end

  if up
    [200, "OK"]
  else
    [503, "Not OK"]
  end
end
