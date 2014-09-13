require 'spec_helper'

require 'health_checker'

describe HealthChecker do
  let (:service_checker) { double }
  let (:checker) { HealthChecker.new(service_checker) }

  it 'should only check status once within a short time window' do
    expect(service_checker).to receive(:check).once
    expect(service_checker).to receive(:check_details).once
    5.times { checker.check }
  end

  it 'should check the service again after 1 second' do
    expect(service_checker).to receive(:check).twice
    expect(service_checker).to receive(:check_details).twice

    5.times { checker.check }
    Timecop.travel(1)
    5.times { checker.check }
  end

  it 'should ensure only a single thread is checking status at a time'
  it 'should handle the case where the check results are too stale'
end
