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

        app.get '/zk/monit_should_restart' do
          check_zk_monit_should_restart
        end
      end

      def check_zk
        statsd.time('whazzup.check_zk') do
          checker = settings.checkers[:zk]

          if checker.check
            [200, JSON.generate(checker.check_details)]
          else
            [503, JSON.generate(checker.check_details)]
          end
        end
      end

      def check_zk_monit_should_restart
        statsd.time('whazzup.check_zk_monit_should_restart') do
          checker = settings.checkers[:zk]

          if checker.check
            [200, checker.check_details['monit_should_restart_details']]
          else
            [503, JSON.generate(checker.check_details)]
          end
        end
      end
    end
  end
end
