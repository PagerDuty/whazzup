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


## XtraDB Cluster Configuration

For an XtraDB cluster, you'll need to have a `health_check` database, and a `state` table in that database.

In a pre-production or production environment, bring up a `mysql` console and execute the following statements:

```
create database if not exists health_check;
create table if not exists health_check.state (
  host_name varchar(128) not null,
  available tinyint(1) not null default 1,
  unique index (host_name));
```

Next, add an entry for all hosts in the cluster:

```
insert into health_check.state values ($HOSTNAME, 1);
...
```

You can confirm that your cluster is correctly configured by running the `curl localhost:9201/xdb`:

e.g.
```
$ curl localhost:9201/xdb
{"wsrep_local_status":"Synced","cluster_size":3,"health_check.state":1,"available":true}
```
