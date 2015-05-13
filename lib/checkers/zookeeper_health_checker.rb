require 'logger'
require 'socket'
require 'timeout'

require 'zk'

class ZookeeperHealthChecker
  attr_accessor :hostname
  attr_accessor :zk_connection_settings
  attr_accessor :zk_outstanding_threshold

  attr_accessor :logger
  attr_accessor :statsd

  # Returns an object that should be passed back to the client to give details
  # on the state of the service
  attr_reader :check_details
  SRVR_NUMERIC_KEYS = Set.new ["Received", "Sent", "Connections", "Outstanding", "Node Count"]
  FIXNUM_MAX = (2**(0.size * 8 -2) -1)

  def initialize(settings = {})
    self.hostname = settings.hostname

    self.logger = settings.check_logger || Logger.new('/dev/null')
    self.statsd = settings.statsd

    self.zk_connection_settings = settings.zk_connection_settings
    self.zk_outstanding_threshold = settings.zk_outstanding_threshold || FIXNUM_MAX
  end

  def check
    logger.debug { 'Checking zk health' }

    srvr_data = get_zk_data('srvr')
    ruok_data = get_zk_data('ruok')

    # Failed to get any zk data so bail out
    if srvr_data.nil?
      @check_details = {'available' => false, 'monit_should_restart' => true}
      return false
    elsif ruok_data.nil?
      @check_details = {'available' => true, 'ruok' => false, 'monit_should_restart' => true}
      return false
    end

    check_details = parse_srvr_data(srvr_data)

    # failed to parse the zk reponse so it might be still starting up
    if check_details.nil?
      @check_details = {'available' => false, 'monit_should_restart' => false}
      return false
    end

    check_details['over_outstanding_threshold'] = check_details['Outstanding'] > zk_outstanding_threshold
    check_details['leader'] = ['leader', 'standalone'].include?(check_details['Mode'])
    check_details['ruok'] = ruok_data[0]
    check_details['wedged'] = check_details['leader'] && check_details['over_outstanding_threshold']

    check_details['monit_should_restart_details'] = "Leader: #{check_details['leader']}\n"\
                                                    "ruok: #{check_details['ruok']}\n"\
                                                    "OverOutstandingThreshold: #{check_details['over_outstanding_threshold']}\n"\
                                                    "Wedged: #{check_details['wedged']}\n"

    check_passed = statsd.time("whazzup.zk.active_health_check") { active_health_check(check_details) }
    check_details['available'] = check_passed

    check_details['monit_should_restart'] = check_details['wedged']

    @check_details = check_details

    check_details['available']
  end

  private

  def active_health_check(check_details)
    node_path = zk_client.create("/#{hostname}", ephemeral: true, sequential: true)
    zk_client.delete(node_path)

    true
  rescue => e
    logger.error { "Caught error during health check: #{e.inspect}\n#{e.backtrace.join("\n")}" }
    false
  end

  def zk_client
    @zk_client ||= ZK.new("#{zk_connection_settings[:host]}:#{zk_connection_settings[:port]}/whazzup")
  end

  def parse_srvr_data(data)
    result = {}
    data.each do |l|
      k,v = l.split(': ')
      next if v.nil?
      if SRVR_NUMERIC_KEYS.include?(k)
        result[k] = v.to_i
      else
        result[k] = v
      end
    end

    return nil if result.empty?
    result
  end

  def get_zk_data(cmd)
    host = zk_connection_settings[:host]
    port = zk_connection_settings[:port]
    timeout_time = zk_connection_settings[:timeout]

    begin
      s = connect(host, port, timeout_time)
      s.send(cmd, 0)

      if IO.select([s], nil, nil, timeout_time)
        recv = s.read.split("\n")
      else
        raise "Read timeout for #{cmd} on connection to #{host}:#{port}"
        return nil
      end
    rescue Errno::ECONNREFUSED
      logger.error { "Connection to #{host}:#{port} was refused" }
      return nil
    rescue IOError => e
      logger.error { e.message }
      return nil
    rescue => e
      logger.error { "#{e.message}\n#{e.backtrace.join("\n")}" }
      return nil
    ensure
      s.close if s
    end

    recv
  end

  # Adapted from http://spin.atomicobject.com/2013/09/30/socket-connection-timeout-ruby/
  def connect(host, port, timeout = 5)
    # Convert the passed host into structures the non-blocking calls
    # can deal with and looks address manually to be IPv6 ready
    addr = Socket.getaddrinfo(host, nil)
    sockaddr = Socket.pack_sockaddr_in(port, addr[0][3])

    Socket.new(Socket.const_get(addr[0][0]), Socket::SOCK_STREAM, 0).tap do |socket|
      socket.setsockopt(Socket::IPPROTO_TCP, Socket::TCP_NODELAY, 1)

      begin
        # Initiate the socket connection in the background. If it doesn't fail
        # immediatelyit will raise an IO::WaitWritable (Errno::EINPROGRESS)
        # indicating the connection is in progress.
        socket.connect_nonblock(sockaddr)

      rescue IO::WaitWritable
        # IO.select will block until the socket is writable or the timeout
        # is exceeded - whichever comes first.
        if IO.select(nil, [socket], nil, timeout)
          begin
            # Verify there is now a good connection
            socket.connect_nonblock(sockaddr)
          rescue Errno::EISCONN
            # Good news everybody, the socket is connected!
          rescue
            # An unexpected exception was raised - the connection is no good.
            socket.close
            raise
          end
        else
          # IO.select returns nil when the socket is not ready before timeout
          # seconds have elapsed
          socket.close
          raise IOError, "Connection timeout to #{host}:#{port}"
        end
      end
    end
  end
end
