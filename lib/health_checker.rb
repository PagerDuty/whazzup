require 'thread'
require 'logger'
require 'statsd'

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
      logger.log(logger.level) { status_changed_message } if status_changed?(last_check_results)

      @last_check_results = last_check_results
      @last_check_details = last_check_details

      logger.log(logger.level) { "Results: #{@last_check_results}" }
      logger.log(logger.level) { "Details: #{@last_check_details}" }

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

  def log_and_track_change
    log_change
    track_change
  end

  def log_change
    logger.log { status_changed_message }
  end

  def stale?
    if @last_check_time
      (Time.now - @last_check_time) > @max_staleness
    else
      true
    end
  end

  def status_changed?(new_check_results)
    @last_check_results ^ new_check_results
  end

  def status_changed_message
    if @last_check_results
      'Status changed from available to unavailable'
    else
      'Status changed from unavailable to available'
    end
  end

  def shutdown
    @keep_checking = false
    @monitor_thread.join
  end

  def track_change
    StatsD.event('Status Change', status_changed_message)
  end
end
