#!/usr/bin/env ruby
project_root = ::File.expand_path(::File.dirname(::File.dirname(::File.dirname(__FILE__))))

require 'yaml'

require_relative "#{project_root}/lib/checkers/zookeeper_health_checker"

class Settings
  attr_accessor :hostname
  attr_accessor :check_logger
  attr_accessor :zk_connection_settings
  attr_accessor :zk_outstanding_threshold

  def initialize
    @hostname = `hostname`.chomp
    @check_logger = ::Logger.new(STDOUT)
    @check_logger.level = ::Logger::INFO

    if ENV['WHAZZUP_CONFIG']
      if ::File.exist?(ENV['WHAZZUP_CONFIG'])
        load_settings_from_file(ENV['WHAZZUP_CONFIG'])
      else
        puts "Config file #{ENV['WHAZZUP_CONFIG']} does not exist! Using default settings..."
        load_default_settings
      end
    else
      load_default_settings
    end
  end

  def load_default_settings
    @zk_connection_settings = {
      host: 'localhost',
      port: 2181,
      timeout: 5
    }
    @zk_outstanding_threshold = 60
  end

  def load_settings_from_file(filename)
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

settings = Settings.new

checker = ZookeeperHealthChecker.new(settings)
checker.check

monit_should_restart = checker.check_details['monit_should_restart']

if monit_should_restart
  exit(1)
else
  exit(0)
end
