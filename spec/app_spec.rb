ENV['RACK_ENV'] = 'test'

require 'app'
require 'rspec'
require 'rack/test'

describe 'Galera health check' do
  include Rack::Test::Methods

  def app
    Sinatra::Application
  end

  def db_client
    app.send(:db_client)
  end

  before do
    app.set(:wsrep_state_dir, 'spec/data/3_node_cluster_synced')
    app.set(:hostname, 'test.local')
  end

  it 'should be marked up if it is a a synced node' do
    get '/'
    expect(last_response.status).to be(200)
  end

  it 'should be marked down if it is a donor node' do
    app.set(:wsrep_state_dir, 'spec/data/3_node_cluster_donor')
    get '/'
    expect(last_response.status).to be(503)
  end

  it 'should be marked up if it is a donor node in a 2 node cluster' do
    app.set(:wsrep_state_dir, 'spec/data/2_node_cluster_donor')
    get '/'
    expect(last_response.status).to be(200)
  end

  it 'should be marked down if it is marked down in the database' do
    begin
      db_client.query("update state set available = 0 where host_name = 'test.local'")

      get '/'
      expect(last_response.status).to be(503)
    ensure
      db_client.query("update state set available = 1 where host_name = 'test.local'")
    end
  end

  it 'should be marked down if no row is found for the desired host in the DB' do
    app.set(:hostname, 'does.not.exist')

    get '/'
    expect(last_response.status).to be(503)
  end
end
