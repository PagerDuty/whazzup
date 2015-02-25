require 'sinatra/base'

module Sinatra
  module Routing
    module Xdb
      def self.registered(app)
        app.get '/xdb' do
          check_xdb
        end

        app.options '/xdb' do
          check_xdb
        end
      end

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
end
