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

  it 'a synced node should be marked up' do
    get '/'
    expect(last_response).to be_ok
    expect(last_response.body).to eq('OK')
  end

  it 'a donor node in a cluster should be marked down' do
    app.set(:wsrep_state_dir, 'spec/data/3_node_cluster_donor')
    get '/'
    expect(last_response.status).to be(503)
  end
end
