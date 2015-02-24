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
    end
  end
end
