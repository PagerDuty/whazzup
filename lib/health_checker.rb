require 'thread'
require 'logger'

class HealthChecker
  CHECK_MUTEX = Mutex.new

  attr_accessor :logger

  def initialize(settings = {})
    @service_checker = settings[:service_checker]
    @max_staleness = settings[:max_staleness]
    self.logger = settings[:logger] || Logger.new('/dev/null')

    @check_interval = 1 # second

    @last_check_time = nil
    @last_check_results = nil
    @last_check_details = nil

    # Initialize with a call to perform check so checks aren't initially seen as stale
    perform_check

    @monitor_thread = Thread.new { monitor_service }
  end

  def check
    logger.debug { 'Monitoring thread died' } unless still_monitoring?

    stale? ? false : @last_check_results
  end

  def check_details
    @last_check_details || {}
  end

  private

  def monitor_service
    while true
      perform_check if check_now?
      sleep @check_interval
    end
  end

  def perform_check
    last_check_results = @service_checker.check
    last_check_details = @service_checker.check_details

    CHECK_MUTEX.synchronize do
      @last_check_results = last_check_results
      @last_check_details = last_check_details

      logger.debug { "Results: #{@last_check_results}" }
      logger.debug { "Details: #{@last_check_details}" }

      @last_check_time = Time.now
    end
  end

  def still_monitoring?
    !!@monitor_thread.status
  end

  def check_now?
    if @last_check_time
      (Time.now - @last_check_time) > @check_interval
    else
      true
    end
  end

  def stale?
    if @last_check_time
      (Time.now - @last_check_time) > @max_staleness
    else
      true
    end
  end
end
