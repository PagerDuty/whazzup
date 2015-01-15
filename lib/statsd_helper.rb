require 'sinatra'
require 'statsd'

module Sinatra
  module StatsdHelper
    def statsd
      @settings ||= Statsd.new(settings.statsd_host, settings.statsd_port)
    end
  end
end
