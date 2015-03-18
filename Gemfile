# A sample Gemfile
source "https://rubygems.org"

gem 'sinatra', '~> 1.4.5'
gem 'puma'

gem 'dogstatsd-ruby', '~> 1.4.1'
gem 'activesupport'

gem 'rspec', groups: [:development, :test]
gem 'rack-test', groups: [:development, :test]
gem 'pry', groups: [:development, :test]

group :development do
  gem 'rake'
  gem 'rb-readline'
  gem 'travis'
end

group :test do
  gem 'aruba'
  gem 'timecop'
end

# Service check dependencies should go in separate groups so we can install the
# check system on different server and not need to install all the dependencies
# for all the (unused) checks.
group :xdb do
  gem 'mysql2', '~> 0.3.16'
end
