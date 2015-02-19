class Whazzup < Sinatra::Base
  get '/xdb' do
    check_xdb
  end

  options '/xdb' do
    check_xdb
  end

  def check_xdb
    statsd.time('whazzup.check_xdb') do
      checker = xdb_checker

      if checker.check
        [200, JSON.generate(checker.check_details)]
      else
        [503, JSON.generate(checker.check_details)]
      end
    end
  end

  def xdb_checker
    settings.checkers[:xdb]
  end
end
