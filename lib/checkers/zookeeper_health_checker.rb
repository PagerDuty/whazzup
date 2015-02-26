require 'logger'
require 'socket'
require 'timeout'

class ZookeeperHealthChecker
  attr_accessor :hostname
  attr_accessor :zk_connection_settings
  attr_accessor :zk_outstanding_threshold

  attr_accessor :logger

  # Returns an object that should be passed back to the client to give details
  # on the state of the service
  attr_reader :check_details

  def initialize(settings = {})
    self.hostname = settings.hostname
    self.logger = settings.check_logger || Logger.new('/dev/null')
    self.zk_connection_settings = settings.zk_connection_settings
    self.zk_outstanding_threshold = settings.zk_outstanding_threshold || 1000
  end

  def check
    logger.debug { 'Checking zk health' }

    check_details = {}
    srvr_data = get_srvr_data
    check_details = parse_srvr_data(srvr_data) unless srvr_data.nil?

    check_details['leader'] = if !srvr_data.nil? && (['leader', 'standalone'].include?(check_details['Mode']))
                                true
                              else
                                false
                              end

    check_details['over_outstanding_threshold'] = if !srvr_data.nil? && check_details['Outstanding'] > zk_outstanding_threshold
                                                    true
                                                  else
                                                    false
                                                  end

    check_details['available'] = if srvr_data.nil?
                                    false
                                  else
                                    true
                                  end

    @check_details = check_details

    check_details['available']
  end

  def parse_srvr_data(data)
    result = {}
    data.each do |l|
      k,v = l.split(': ')
      result[k] = v
    end

    result['Received'] = result['Received'].to_i
    result['Sent'] = result['Sent'].to_i
    result['Connections'] = result['Connections'].to_i
    result['Outstanding'] = result['Outstanding'].to_i
    result['Node count'] = result['Node count'].to_i

    result
  end

  def get_srvr_data
    host = zk_connection_settings[:host]
    port = zk_connection_settings[:port]
    timeout_time = zk_connection_settings[:timeout]
    begin
      s = TCPSocket.open(host, port)
    rescue Errno::ECONNREFUSED => e
      logger.error { "Connection to #{host}:#{port} was refused" }
      return nil
    end

    s.send('srvr', 0)

    recv = []
    begin
      timeout(timeout_time) do
        while line = s.gets
          recv.push(line.chop)
        end
      end
    rescue Timeout::Error => e
      logger.error { "Connection to #{host}:#{port} timed out after #{timeout_time}s" }
      return nil
    end
    s.close

    recv
  end
end
