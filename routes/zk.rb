require 'sinatra/base'

module Sinatra
  module Routing
    module Zk
      def self.registered(app)
        app.get '/zk' do
          check_zk
        end

        app.options '/zk' do
          check_zk
        end
      end

      def check_zk
        statsd.time('whazzup.check_zk') do
          checker = settings.checkers[:zk]

          if checker.check && !checker.check_details['over_outstanding_threshold']
            [200, JSON.generate(checker.check_details)]
          else
            [503, JSON.generate(checker.check_details)]
          end
        end
      end
    end
  end
end
