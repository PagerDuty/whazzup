ENV['RACK_ENV'] = 'test'

require 'app'
require 'rspec'
require 'rack/test'

describe 'Zookeeper health check' do
  include Rack::Test::Methods

  def app
    Whazzup.new
  end

  before do
    Whazzup.set(:hostname, 'test.local')
  end

  it 'should require and initialize checkers, and make a first check' do
    Whazzup.set(:services, [:zk])
    expect_any_instance_of(Whazzup).to receive(:require_relative).with 'lib/checkers/zookeeper_health_checker'

    service_checker_class = double
    expect(Whazzup::SERVICE_CHECKERS[:zk]).to receive(:constantize) { service_checker_class }
    expect(service_checker_class).to receive(:new)

    health_checker = double
    expect(HealthChecker).to receive(:new).once { health_checker }
    expect(health_checker).to receive(:check).once

    app
  end

  it 'should be marked up if it is a good node' do
    get '/zk'
    expect(last_response.status).to be(200)
  end

  it 'should support the OPTIONS method for checking health (HAProxy default method)' do
    options '/zk'
    expect(last_response.status).to be(200)
  end

  it 'should be marked down if outstanding threshold is exceeded' do
    Whazzup.set(:zk_outstanding_threshold, -1)
    get '/zk'
    expect(last_response.status).to be(503)
  end

  it 'should be marked down if the connect to zookeeper times out' do
    allow_any_instance_of(Timeout).to receive(:timeout).and_raise(Timeout::Error, 'mocking connection timeout')
    get '/zk'
    expect(last_response.status).to be(503)
  end

  it 'should be marked down if the connect to zookeeper is refused' do
    allow_any_instance_of(TCPSocket).to receive(:open).and_raise(Errno::ECONNREFUSED, 'mocking connection failure')
    get '/zk'
    expect(last_response.status).to be(503)
  end

  it 'should be marked down if zookeeper is unavailable' do
    allow_any_instance_of(ZookeeperHealthChecker).to receive(:check).and_return(false)
    get '/zk'
    expect(last_response.status).to be(503)
  end
end
