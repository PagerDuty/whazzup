require 'sinatra'
require 'json'
require 'yaml'
require 'active_support/inflector'

require_relative 'lib/statsd_helper'
require_relative 'lib/config'
require_relative 'lib/routes'
require_relative 'lib/checkers'

class Whazzup < Sinatra::Base
  helpers Sinatra::StatsdHelper

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
        statsd: statsd
      )

      # Ensure connection by firing an initial check
      settings.checkers[service].check
    end
  end
end
