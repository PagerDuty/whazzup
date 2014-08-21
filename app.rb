require 'sinatra'

configure do
  set :wsrep_state_dir, '/etc/mysql/wsrep'
end

get '/' do
  state = File.read(File.join(settings.wsrep_state_dir, 'status')).strip
  size = File.read(File.join(settings.wsrep_state_dir, 'size')).strip

  if state == 'Synced'
    [200, "OK"]
  else
    [503, "Not OK"]
  end
end
