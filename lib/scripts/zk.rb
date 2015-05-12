require 'yaml'
require 'checkers/zookeeper_health_checker'
require 'socket'

class Settings
  attr_accessor :hostname
  attr_accessor :check_logger
  attr_accessor :zk_connection_settings
  attr_accessor :zk_outstanding_threshold

  def initialize
    @hostname = Socket.gethostname
    @check_logger = ::Logger.new(STDOUT)
    @check_logger.level = ::Logger::INFO

    config_file = ENV['WHAZZUP_CONFIG']

    @check_logger.debug { "Config: #{config_file}" }

    if config_file
      if ::File.exist?(config_file)
        begin
          load_settings_from_file(config_file)
        rescue
          @check_logger.error { "#{config_file} is invalid!" }
          exit(1)
        end
      else
        @check_logger.warn { "Config file #{config_file} does not exist! Using default settings..." }
        load_default_settings
      end
    else
      load_default_settings
    end
  end

  private

  def load_default_settings
    @check_logger.debug { 'Loading config from defaults' }
    @zk_connection_settings = {
      host: 'localhost',
      port: 2181,
      timeout: 5
    }
    @zk_outstanding_threshold = 60
  end

  def load_settings_from_file(filename)
    @check_logger.debug { "Loading config from #{filename}" }
    config = ::YAML.load_file(filename)

    if config['zk']
      @zk_connection_settings = {
        host: config['zk']['host'],
        port: config['zk']['port'],
        timeout: config['zk']['timeout']
      }
      @zk_outstanding_threshold = config['zk']['outstanding_threshold']
    end
  end
end

class ZkCheck
  def initialize(argv, stdin=STDIN, stdout=STDOUT, stderr=STDERR, kernel=Kernel)
    @argv, @stdin, @stdout, @stderr, @kernel = argv, stdin, stdout, stderr, kernel
  end

  def execute!
    settings = Settings.new

    checker = ZookeeperHealthChecker.new(settings)
    checker.check

    monit_should_restart = checker.check_details['monit_should_restart']

    exitstatus = monit_should_restart ? 255 : 0

    exit(exitstatus)
  end
end
