require 'sinatra/base'
require 'json'
require 'yaml'
require 'active_support/inflector'

# General checkers
require_relative 'lib/checkers/health_checker'

# General helpers
require_relative 'lib/helpers/statsd_helper'

# config
require_relative 'config'

class Whazzup < Sinatra::Base
  SERVICE_CHECKERS = {
    xdb: 'GaleraHealthChecker',
    zk: 'ZookeeperHealthChecker'
  }.freeze

  # General extention setup
  register Sinatra::Config
  helpers Helpers::StatsdHelper

  # XDB specific extention setup
  if settings.services.include?(:xdb)
    require_relative 'routes/xdb'
    register Sinatra::Routing::Xdb
    helpers Sinatra::Routing::Xdb
  end

  # ZK specific extention setup
  if settings.services.include?(:zk)
    require_relative 'routes/zk'
    register Sinatra::Routing::Zk
    helpers Sinatra::Routing::Zk
  end

  def initialize
    super
    initialize_checkers
  end

  def initialize_checkers
    settings.services.each do |service|
      checker_class_name = SERVICE_CHECKERS[service]
      require_relative "lib/checkers/#{checker_class_name.underscore}"

      # Initialize and memoize instance of checker class
      checker_class = checker_class_name.constantize
      service_checker = checker_class.new(settings)

      settings.checkers[service] = HealthChecker.new(
        service_checker: service_checker,
        max_staleness: settings.max_staleness,
        logger: settings.check_logger,
        statsd: statsd,
        service: service
      )

      # Ensure connection by firing an initial check
      settings.checkers[service].check
    end
  end
end
