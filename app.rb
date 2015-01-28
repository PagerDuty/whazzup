require 'sinatra'
require 'json'
require 'yaml'
require 'active_support/inflector'

require_relative 'lib/statsd_helper'
require_relative 'lib/health_checker'

class Whazzup < Sinatra::Base
  helpers Sinatra::StatsdHelper

  SERVICE_CHECKERS = {
    xdb: 'GaleraHealthChecker'
  }.freeze

  configure do
    set :wsrep_state_dir, '/etc/mysql/wsrep'

    set(:hostname) { `hostname`.chomp }

    logger = Logger.new('log/check.log')
    logger.level = Logger::INFO
    set :check_logger, logger
    set :checkers, {}

    set :max_staleness, 10

    set :statsd_host, '127.0.0.1'
    set :statsd_port, 8125

    set :services, [:xdb]
  end

  configure :production do
    config = YAML.load_file ENV['WHAZZUP_CONFIG']
    set :services, config['services'].map(&:to_sym)

    set :connection_settings, {
      host: 'localhost',
      username: config['connection_settings']['username'],
      password: config['connection_settings']['password'],
      database: 'health_check'
    }
  end

  configure :development do
    set :wsrep_state_dir, 'spec/data/3_node_cluster_synced'
    set :connection_settings, {
      host: 'localhost',
      username: 'root',
      database: 'health_check'
    }
    set :hostname, 'dev.local'

    logger = Logger.new(STDOUT)
    logger.level = Logger::DEBUG
    set :check_logger, logger
  end

  configure :test do
    set :connection_settings, {
      host: 'localhost',
      username: 'root',
      database: 'health_check'
    }
    set :hostname, 'test.local'

    logger = Logger.new('/dev/null')
    logger.level = Logger::DEBUG
    set :check_logger, logger

    set :statsd_host, '0.0.0.0'
  end

  def initialize
    super
    initialize_checkers
  end

  get '/xdb' do
    check_xdb
  end

  options '/xdb' do
    check_xdb
  end

  def check_xdb
    statsd.time('whazzup.check_xdb') do
      checker = xdb_checker

      if checker.check
        [200, JSON.generate(checker.check_details)]
      else
        [503, JSON.generate(checker.check_details)]
      end
    end
  end

  def xdb_checker
    settings.checkers[:xdb]
  end

  def initialize_checkers
    settings.services.each do |service|
      checker_class_name = SERVICE_CHECKERS[service]
      require_relative "lib/#{checker_class_name.underscore}"

      # Initialize and memoize instance of checker class
      # TODO: Service specific configs should be pulled from a file, this is xdb specific
      checker_class = checker_class_name.constantize
      service_checker = checker_class.new(
        wsrep_state_dir: settings.wsrep_state_dir,
        connection_settings: settings.connection_settings,
        hostname: settings.hostname,
        logger: settings.check_logger
      )

      settings.checkers[service] = HealthChecker.new(
        service_checker: service_checker,
        max_staleness: settings.max_staleness,
        logger: settings.check_logger,
        statsd: statsd
      )

      # Ensure connection by firing an initial check
      settings.checkers[service].check
    end
  end
end
