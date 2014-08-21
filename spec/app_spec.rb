ENV['RACK_ENV'] = 'test'

require 'app'
require 'rspec'
require 'rack/test'

describe 'Galera health check' do
  include Rack::Test::Methods

  def app
    Sinatra::Application
  end

  before do
    app.set(:wsrep_state_dir, 'spec/data/3_node_cluster_synced')
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
end
