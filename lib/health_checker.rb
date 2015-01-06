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

    @keep_checking = true
    @monitor_thread = Thread.new do
      Thread.current.abort_on_exception = true
      monitor_service
    end
  end

  def check
    stale? ? false : @last_check_results
  end

  def check_details
    @last_check_details || {}
  end

  private

  def monitor_service
    while @keep_checking
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

      logger.log { "Results: #{@last_check_results}" }
      logger.log { "Details: #{@last_check_details}" }

      @last_check_time = Time.now
    end
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

  def shutdown
    @keep_checking = false
    @monitor_thread.join
  end
end
