require 'aruba'
require 'aruba/api'
require 'rspec'
require 'timecop'

Timecop.freeze

module CliSpecHelpers
  def zk(args = nil, env = nil)
    run_simple("#{env} #{zk_script} #{args}", false)
  end

  def zk_script
    File.expand_path('../../lib/scripts/zk.rb', __FILE__)
  end
end

RSpec.configure do |config|
  config.include CliSpecHelpers
  config.include Aruba::Api
end
