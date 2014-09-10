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
  checker = GaleraHealthChecker.new(
    wsrep_state_dir: settings.wsrep_state_dir,
    connection_settings: {
      host: 'localhost',
      username: 'root', 
      database: 'health_check'
    },
    hostname: settings.hostname
  )

  if checker.check
    [200, JSON.generate(checker.check_details)]
  else
    [503, JSON.generate(checker.check_details)]
  end
end

class GaleraHealthChecker
  attr_accessor :wsrep_state_dir
  attr_accessor :connection_settings
  attr_accessor :hostname

  # Returns an object that should be passed back to the client to give details
  # on the state of the service
  attr_reader :check_details

  def initialize(settings = {})
    self.wsrep_state_dir = settings[:wsrep_state_dir]
    self.connection_settings = settings[:connection_settings]
    self.hostname = settings[:hostname]
  end

  # Returns true if the service is up
  def check
    check_details = {}

    up = check_wsrep_state(check_details)
    up &&= check_state_table(check_details)

    check_details['available'] = up

    @check_details = check_details

    return up
  end

  def check_wsrep_state(check_details)
    begin
      state = File.read(File.join(wsrep_state_dir, 'status')).strip
      size = File.read(File.join(wsrep_state_dir, 'size')).strip.to_i
    rescue => e
      # TODO log the exception here
    end

    check_details['wsrep_local_status'] = state
    check_details['cluster_size'] = size

    up = case state
         when 'Synced'
           true
         when 'Donor'
           size == 2
         else
           false
         end

    return up
  end

  def check_state_table(check_details)
    begin
      results = db_client.query("SELECT available FROM state WHERE host_name = '#{hostname}'")
      health_check_state = results.first ? results.first['available'] : 0
    rescue => e
      health_check_state = 0
    end

    check_details['health_check.state'] = health_check_state

    return health_check_state == 1
  end
end

def db_client
  @db_client ||= Mysql2::Client.new(
    host: 'localhost',
    username: 'root', 
    database: 'health_check'
  )
end
