require 'thread'
require 'logger'

class HealthChecker
  CHECK_MUTEX = Mutex.new

  attr_accessor :logger

  def initialize(settings = {})
    @service_checker = settings[:service_checker]
    self.logger = settings[:logger] || Logger.new('/dev/null')

    @check_interval = 1 # second

    @last_check_time = nil
    @last_check_results = nil
    @last_check_details = nil
  end

  def check
    CHECK_MUTEX.synchronize do
      if check_now?
        @last_check_results = @service_checker.check
        @last_check_details = @service_checker.check_details

        logger.debug { "Results: #{@last_check_results}" }
        logger.debug { "Details: #{@last_check_details}" }

        @last_check_time = Time.now
      end
    end

    @last_check_results
  end

  def check_details
    @last_check_details
  end

  private
  def check_now?
    if @last_check_time
      (Time.now - @last_check_time) > @check_interval
    else
      true
    end
  end
end
