require 'rspec/core/rake_task'

RSpec::Core::RakeTask.new(:spec) do |t|
  t.ruby_opts = %w( -I . )
end

task :default => :spec
