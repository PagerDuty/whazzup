require 'aruba'
require 'aruba/api'
require 'rspec'
require 'timecop'

Timecop.freeze

module CliSpecHelpers
  def zk(args = nil, env = nil)
    restore_env
    if env
      env.each do |k,v|
        set_env(k.to_s,v)
      end
    end
    run_simple("#{zk_script} #{args}", false)
  end

  def zk_script
    File.expand_path('../../bin/zk_check', __FILE__)
  end
end

RSpec.configure do |config|
  config.include CliSpecHelpers
  config.include Aruba::Api
end
