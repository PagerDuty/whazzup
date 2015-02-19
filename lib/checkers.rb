require_relative 'checkers/health_checker'


class Whazzup < Sinatra::Base
  SERVICE_CHECKERS = {
    xdb: 'GaleraHealthChecker'
  }.freeze
end
