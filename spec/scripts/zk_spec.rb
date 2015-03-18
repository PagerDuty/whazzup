require 'spec_helper'
project_root = ::File.expand_path(::File.dirname(::File.dirname(::File.dirname(__FILE__))))
require_relative "#{project_root}/lib/checkers/zookeeper_health_checker"

describe 'zk check script' do
  it 'should pass when Zookeeper is running as expected' do
    zk
    assert_success(0)
  end

  it 'should pass when Zookeeper is running as expected when given a config file' do
    zk(env = "ENV['WHAZZUP_CONFIG']=../data/config_good.yml")
    assert_success(0)
  end

  it 'should fail with exit code 255 when given a bad config file' do
    zk(env = "ENV['WHAZZUP_CONFIG']=../data/config_bad.yml")
    assert_success(255)
  end

  it 'should fail when Zookeeper is down' do
    zk(env = "ENV['WHAZZUP_CONFIG']=../data/config_good_dummy.yml")
    assert_success(255)
  end
end
