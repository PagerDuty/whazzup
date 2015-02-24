require 'rspec/core/rake_task'
require 'rubocop/rake_task'

RSpec::Core::RakeTask.new(:spec) do |t|
  t.ruby_opts = %w( -I . )
end

task default: [:rubocop, :spec]

namespace :db do
  def db_client
    require 'mysql2'
    @client ||= Mysql2::Client.new(
      host: 'localhost',
      username: 'root')
  end

  task :create do
    db_client.query('create database if not exists health_check;')
    db_client.query <<-SQL
      create table if not exists health_check.state (
        host_name varchar(128) not null,
        available tinyint(1) not null default 1,
        unique index (host_name));
    SQL
  end

  task :seed do
    db_client.query <<-SQL
      insert ignore into health_check.state(host_name, available)
             values ('dev.local', 1), ('test.local', 1);
    SQL
  end

  task :setup => [:create, :seed]
end

desc 'rubocop compliancy checks'
RuboCop::RakeTask.new(:rubocop) do |t|
  t.patterns = %w{ lib/**/*.rb lib/*.rb spec/*.rb *.rb }
end
