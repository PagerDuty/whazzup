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
    @db_client ||= Mysql2::Client.new(app.connection_settings)
  end

  before do
    app.set(:wsrep_state_dir, 'spec/data/3_node_cluster_synced')
    app.set(:hostname, 'test.local')

    app.settings.checkers.clear
  end

  it 'should be marked up if it is a a synced node' do
    get '/xdb'
    expect(last_response.status).to be(200)
  end

  it 'should be marked down if it is a donor node' do
    app.set(:wsrep_state_dir, 'spec/data/3_node_cluster_donor')
    get '/xdb'
    expect(last_response.status).to be(503)
  end

  it 'should be marked up if it is a donor node in a 2 node cluster' do
    app.set(:wsrep_state_dir, 'spec/data/2_node_cluster_donor')
    get '/xdb'
    expect(last_response.status).to be(200)
  end

  it 'should be marked down if the wsrep state files cannot be read' do
    app.set(:wsrep_state_dir, 'does/not/exist')
    get '/xdb'
    expect(last_response.status).to be(503)
  end

  it 'should be marked down if it is marked down in the database' do
    begin
      db_client.query("update state set available = 0 where host_name = 'test.local'")

      get '/xdb'
      expect(last_response.status).to be(503)
    ensure
      db_client.query("update state set available = 1 where host_name = 'test.local'")
    end
  end

  it 'should be marked down if no row is found for the desired host in the DB' do
    app.set(:hostname, 'does.not.exist')

    get '/xdb'
    expect(last_response.status).to be(503)
  end

  it 'should be marked down if there is trouble connecting to the database' do
    expect_any_instance_of(Mysql2::Client).to receive(:query).and_raise(Mysql2::Error, 'mocking connection failure')

    get '/xdb'
    expect(last_response.status).to be(503)
  end
end
