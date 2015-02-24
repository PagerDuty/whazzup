require 'sinatra/base'

module Helpers
  module Xdb
    def check_xdb
      statsd.time('whazzup.check_xdb') do
        checker = settings.checkers[:xdb]

        if checker.check
          [200, JSON.generate(checker.check_details)]
        else
          [503, JSON.generate(checker.check_details)]
        end
      end
    end
  end
end
