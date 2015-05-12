require 'spec_helper'

describe 'zk check script' do
  it 'should pass when Zookeeper is running as expected' do
    zk
    assert_exit_status(0)
  end

  it 'should pass when Zookeeper is running as expected when given a config file' do
    zk nil, { WHAZZUP_CONFIG: "../../spec/data/config_good.yml" }
    assert_exit_status(0)
  end

  it 'should fail with exit code 1 when given a bad config file' do
    zk nil, { WHAZZUP_CONFIG: "../../spec/data/config_bad.yml" }
    assert_exit_status(1)
  end

  it 'should fail with exit code 255 when Zookeeper should be restarted' do
    zk nil, { WHAZZUP_CONFIG: "../../spec/data/config_good_dummy.yml" }
    assert_exit_status(255)
  end
end
