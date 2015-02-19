class Whazzup < Sinatra::Base
  configure :production do
    config = YAML.load_file ENV['WHAZZUP_CONFIG']
    set :services, config['services'].map(&:to_sym)

    set :connection_settings, {
      host: 'localhost',
      username: config['connection_settings']['username'],
      password: config['connection_settings']['password'],
      database: 'health_check',
      reconnect: true
    }
  end
end
