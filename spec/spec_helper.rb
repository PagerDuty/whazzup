require 'aruba'
require 'aruba/api'
require 'rspec'
require 'timecop'

Timecop.freeze

module CliSpecHelpers
  def zk(args = nil)
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
