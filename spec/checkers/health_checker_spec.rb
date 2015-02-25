require 'spec_helper'

require 'checkers/health_checker'

describe HealthChecker do
  let(:service_checker) { double }
  let(:statsd) { Statsd.new('0.0.0.0') }
  let(:checker) { HealthChecker.new(service_checker: service_checker, max_staleness: 120, statsd: statsd) }

  after :each do
    checker.send :shutdown rescue nil
  end

  context 'initialization' do

    it 'should call perform_check during initialization' do
      expect(service_checker).to receive(:check).once
      expect(service_checker).to receive(:check_details).once
      checker
    end

    it 'should start a background thread during initialization' do
      allow(service_checker).to receive(:check).once
      allow(service_checker).to receive(:check_details).once
      expect(checker.instance_variable_get :@monitor_thread).to be_kind_of Thread
    end
  end

  context 'after initialization' do
    let(:check_details) { { up: true } }
    before :each do
      allow(service_checker).to receive(:check) { true }
      allow(service_checker).to receive(:check_details) { check_details }
      allow_any_instance_of(HealthChecker).to receive(:monitor_service).and_return true
    end

    it 'check should serve a cached check' do
      expect(checker).not_to receive(:perform_check)
      expect(checker).to receive(:stale?) { false }
      expect(checker.check).to be(true)
    end

    it 'multiple calls to check should not check the service' do
      expect(checker).not_to receive(:perform_check)

      threads = 5.times.map {
        Thread.new do
          checker.check
        end
      }

      threads.each { |t| t.join }
    end

    it 'should return a false if the last check is stale' do
      expect(checker).not_to receive(:perform_check)
      expect(checker).to receive(:stale?).once.and_return true
      expect(checker.check).to be false
    end

    context 'status changes' do
      let(:failed_check_details) { { up: false } }
      it 'should emit a statsd event' do
        allow(service_checker).to receive(:check).once { true }
        allow(service_checker).to receive(:check_details).once { check_details }
        checker.check
        allow(service_checker).to receive(:check).once { false }
        allow(service_checker).to receive(:check_details).once { failed_check_details }

        expect(statsd).to receive(:event).with(
          'whazzup.status_changed',
          'Status changed from available to unavailable'
        )

        # Use send because we don't want to wait check_interval
        checker.send :perform_check
      end
    end
  end

  context 'background monitoring process' do
    it 'should raise an exception if something goes wrong in monitor_thread' do
      allow_any_instance_of(HealthChecker).to receive(:perform_check) { true }
      allow_any_instance_of(HealthChecker).to receive(:monitor_service) { raise StandardError }

      # Sleep to make sure monitor_service gets called from the thread
      expect { checker; sleep(5) }.to raise_error StandardError
    end
  end
end
