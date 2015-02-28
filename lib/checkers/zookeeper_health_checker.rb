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
  SRVR_NUMERIC_KEYS = Set.new ["Received", "Sent", "Connections", "Outstanding", "Node Count"]
  FIXNUM_MAX = (2**(0.size * 8 -2) -1)

  def initialize(settings = {})
    self.hostname = settings.hostname
    self.logger = settings.check_logger || Logger.new('/dev/null')
    self.zk_connection_settings = settings.zk_connection_settings
    self.zk_outstanding_threshold = settings.zk_outstanding_threshold || FIXNUM_MAX
  end

  def check
    logger.debug { 'Checking zk health' }

    check_details = {'available' => false}

    srvr_data = get_srvr_data

    # Failed to get any zk data so bail out
    return false if srvr_data.nil?

    check_details = parse_srvr_data(srvr_data)

    check_details['leader'] = ['leader', 'standalone'].include?(check_details['Mode'])

    check_details['over_outstanding_threshold'] = check_details['Outstanding'] > zk_outstanding_threshold

    check_details['available'] = true

    @check_details = check_details

    check_details['available']
  end

  private

  def parse_srvr_data(data)
    result = {}
    data.each do |l|
      k,v = l.split(': ')
      if SRVR_NUMERIC_KEYS.include?(k)
        result[k] = v.to_i
      else
        result[k] = v
      end
    end

    result
  end

  def get_srvr_data
    host = zk_connection_settings[:host]
    port = zk_connection_settings[:port]
    timeout_time = zk_connection_settings[:timeout]

    begin
      s = connect(host, port, timeout_time)
      s.send('srvr', 0)

      if IO.select([s], nil, nil, timeout_time)
        recv = s.read.split("\n")
      else
        raise "Read timeout on connection to #{host}:#{port}"
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
