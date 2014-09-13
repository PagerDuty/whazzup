class HealthChecker
  def initialize(service_checker)
    @service_checker = service_checker

    @check_interval = 1 # second

    @last_check_time = nil
    @last_check_results = nil
    @last_check_details = nil
  end

  def check
    if check_now?
      @last_check_results = @service_checker.check
      @last_check_details = @service_checker.check_details

      @last_check_time = Time.now
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
