require 'sinatra/base'

module Sinatra
  module Config
    module Production
      def self.registered(app)
        app.configure :production do
          config = YAML.load_file ENV['WHAZZUP_CONFIG']
          app.set :services, config['services'].map(&:to_sym)

          app.set :connection_settings, {
            host: 'localhost',
            username: config['connection_settings']['username'],
            password: config['connection_settings']['password'],
            database: 'health_check',
            reconnect: true
          }
        end
      end
    end
  end
end
