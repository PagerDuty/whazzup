require 'spec_helper'

require 'health_checker'

describe HealthChecker do
  let(:service_checker) { double }
  let(:checker) { HealthChecker.new(service_checker: service_checker, max_staleness: 120) }

  it 'should call perform_check during initialization' do
    expect(service_checker).to receive(:check).once
    expect(service_checker).to receive(:check_details).once
    checker
  end

  it 'should only check status once within a short time window' do
    expect(service_checker).to receive(:check).once
    expect(service_checker).to receive(:check_details).once

    5.times { checker.check }
    sleep 0.1
  end

  it 'should check the service again after check_interval' do
    expect(service_checker).to receive(:check).twice
    expect(service_checker).to receive(:check_details).twice


    Timecop.freeze
    expect_any_instance_of(HealthChecker).to receive(:sleep) { Timecop.travel 2 }.once
    checker
    sleep 0.1
  end

  it 'should ensure only a single thread is checking status at a time' do
    expect(service_checker).to receive(:check).once
    expect(service_checker).to receive(:check_details).once

    threads = 5.times.map {
      Thread.new do
        checker.check
      end
    }
    threads.each { |t| t.join }
    sleep 0.1
  end

  it 'should return a false if the last check is stale' do
    allow(service_checker).to receive(:check)
    allow(service_checker).to receive(:check_details)

    expect(checker).to receive(:stale?).once.and_return true
    expect(checker.check).to be false
  end
end
