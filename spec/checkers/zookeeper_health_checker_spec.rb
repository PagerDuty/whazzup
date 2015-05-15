require 'spec_helper'

require 'app'
require 'checkers/zookeeper_health_checker'

describe ZookeeperHealthChecker do
  let(:settings) { Whazzup.new.settings }
  let(:checker) { ZookeeperHealthChecker.new(settings) }

  it 'returns true if all the health checks pass' do
    expect(checker.check).to eq(true)
  end

  it 'returns false if srvr command fails' do
    expect(checker).to receive(:get_zk_data).with('srvr').and_return(nil)
    expect(checker).to receive(:get_zk_data).with('ruok').and_call_original

    expect(checker.check).to eq(false)
  end

  it 'returns false if ruok command fails' do
    expect(checker).to receive(:get_zk_data).with('srvr').and_call_original
    expect(checker).to receive(:get_zk_data).with('ruok').and_return(nil)

    expect(checker.check).to eq(false)
  end

  it 'returns false if active health check throws an error creating node' do
    mock_zk_client = double('zk_client')
    expect(checker).to receive(:zk_client).and_return(mock_zk_client)
    expect(mock_zk_client).to receive(:create).and_raise(ZK::Exceptions::NoNode)

    expect(checker.check).to eq(false)
  end

  it 'returns false if active health check times out' do
    mock_zk_client = double('zk_client')
    expect(checker).to receive(:zk_client).and_return(mock_zk_client)
    expect(mock_zk_client).to receive(:create).and_raise(Zookeeper::Exceptions::ContinuationTimeoutError)

    expect(checker.check).to eq(false)
  end
end
