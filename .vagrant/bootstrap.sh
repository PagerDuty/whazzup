#!/usr/bin/env bash

apt-get update

# install ruby
apt-get install git libssl-dev -y
git clone https://github.com/sstephenson/rbenv.git /home/vagrant/.rbenv
git clone https://github.com/sstephenson/ruby-build.git /home/vagrant/.rbenv/plugins/ruby-build
echo 'source ~/.bashrc' >> /home/vagrant/.bash_profile
echo 'export PATH="$HOME/.rbenv/bin:$PATH"' >> /home/vagrant/.bash_profile
echo 'eval "$(rbenv init -)"' >> /home/vagrant/.bash_profile
chown vagrant:vagrant -R /home/vagrant/
su - vagrant -c 'rbenv install $(cat /vagrant/.ruby-version)'
su - vagrant -c 'rbenv global $(cat /vagrant/.ruby-version)'

# install xtradb
export DEBIAN_FRONTEND=noninteractive
echo 'percona-xtradb-cluster-server-5.5 mysql-server/root_password password test' | debconf-set-selections
echo 'percona-xtradb-cluster-server-5.5 mysql-server/root_password_again password test' | debconf-set-selections
apt-get install percona-xtradb-cluster-server-5.5 -y
mysqladmin -u root -p'test' password ''

# install zookeeper
apt-get install zookeeperd -y

# setup repo for dev
apt-get install libmysqlclient-dev -y
su - vagrant -c 'gem install bundler'
su - vagrant -c 'cd /vagrant; bundle install --path .bundle'
su - vagrant -c 'cd /vagrant; bundle exec rake db:setup'

# clean up
unset DEBIAN_FRONTEND
