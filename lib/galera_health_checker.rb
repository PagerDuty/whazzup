require 'logger'
require 'mysql2'

class GaleraHealthChecker
  attr_accessor :wsrep_state_dir
  attr_accessor :connection_settings
  attr_accessor :hostname

  attr_accessor :logger

  # Returns an object that should be passed back to the client to give details
  # on the state of the service
  attr_reader :check_details

  def initialize(settings = {})
    self.wsrep_state_dir = settings[:wsrep_state_dir]
    self.connection_settings = settings[:connection_settings]
    self.hostname = settings[:hostname]
    self.logger = settings[:logger] || Logger.new('/dev/null')
  end

  # Returns true if the service is up
  def check
    logger.debug { "Checking galera health" }

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
      logger.error { "#{e.message}\n#{e.backtrace.join("\n")}" }
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
      logger.error { "#{e.message}\n#{e.backtrace.join("\n")}" }
      health_check_state = 0
    end

    check_details['health_check.state'] = health_check_state

    return health_check_state == 1
  end

  def db_client
    @db_client ||= Mysql2::Client.new(connection_settings)
  end
end
