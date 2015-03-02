# whazzup

A home for various health check scripts. Health check results are exposed via HTTP, which HAProxy or other clients can hit. The health checks themselves will be rate limited so the number of checks doesn't grow as the number of clients do.

## Testing

### Setup Vagrant

- `vagrant up`
- `vagrant ssh`
- `cd /vagrant`

### Running Rake tests

Setup vagrant then run `bundle exec rake`

### Running the app in dev

Setup vagrant then run `bundle exec puma -p 9201 -e development`.  Verify it is running by doing `curl localhost:9201` and you should get a 404.

## Routes ##

Check using `curl localhost:9201/<route>`

- `/xdb` - XDB node status
- `/zk` - ZK node status
- `/zk/monit_should_restart` - ZK node status for triggering a Monit restart
