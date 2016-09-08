# lma_collector

## Overview

The `lma_collector` module lets you use Puppet to configure and deploy
collectors of the LMA (Logging, Monitoring and Alerting) toolchain.

The main components of an LMA collector are:

* [Heka](http://hekad.readthedocs.org). Heka is used to process log,
  notification and metric messages, and persist these messages into
  Elasticsearch and InfluxDB.

* [collectd](http://collectd.org/). collectd is used for collecting
  performance statistics from various sources.

The following versions of Heka and collectd are known to work for LMA:

* Heka v0.10.0 (`heka_0.10.0_amd64.deb`)
* collectd v5.4.0 (`collectd_5.4.0-3ubuntu2_amd64.deb`)

## Usage

### Setup

To install and configure the main components, declare the `lma_collector`
class and `lma_collector::heka` defines:

```puppet
class { 'lma_collector': }

lma_collector::heka { 'log_collector':
  require  => Class['lma_collector'],
}

lma_collector::heka { 'metric_collector':
  require  => Class['lma_collector'],
}
```

This installs Heka and configures it with Heka plugins necessary for LMA.

Here is another example where a custom Heka message field is specified:

```puppet
class {'lma_collector':
  tags => {
    tag_A => 'some value'
  }
}
```

### Collect system logs

To make the Collector collect standard system logs from log files in `/var/log`
declare the `lma_collector::logs::system` class:

```puppet
class { 'lma_collector::logs::system': }
```

### Collect OpenStack logs

To make the collector collect logs created by an OpenStack service declare the
`lma_collector::logs::openstack` define. This is an example for the Nova logs:

```puppet
lma_collector::logs::openstack { 'nova': }
```

This configures Heka to read the Nova logs from the log files located in
`/var/log/nova/`.

For Swift a specific class should be declared. For example:

```puppet
class { 'lma_collector::logs::swift':
  file_match    => 'swift-all\.log$',
}
```

For Keystone, in addition to declaring the `lma_collector::logs::openstack`
define, the `lma_collector::logs::keystone_wsgi` class should be declared
to read Keystone logs stored from Apache log files:

```puppet
class { 'lma_collector::logs::keystone_wsgi': }
```

### Collect libvirt logs

To make the collector collect logs created by libvirt declare the
`lma_collector::logs::libvirt` class:

```puppet
class { 'lma_collector::logs::libvirt': }
```

### Collect MySQL logs

To make the collector collect logs created by MySQL declare the
`lma_collector::logs::mysql` class:

```puppet
class { 'lma_collector::logs::mysql': }
```

### Collect Open vSwitch logs

To make the collector collect logs created by Open vSwitch declare the
`lma_collector::logs::ovs` class:

```puppet
class { 'lma_collector::logs::ovs': }
```

### Collect Pacemaker logs

To make the collector collect logs created by Pacemaker declare the
`lma_collector::logs::pacemaker` class:

```puppet
class { 'lma_collector::logs::pacemaker': }
```

### Collect RabbitMQ logs

To make the collector collect logs created by RabbitMQ declare the
`lma_collector::logs::rabbitmq` class:

```puppet
class { 'lma_collector::logs::rabbitmq': }
```

### Derive HTTP metrics from logs

To make the collector create HTTP metrics from OpenStack log messages that
include HTTP information (method, status, and response time) declare the
`lma_collector::logs::aggregated_http_metrics` class:

```puppet
class { 'lma_collector::logs::aggregated_http_metrics': }
```

### Store logs into Elasticsearch

To make the collector store the collected logs into Elasticsearch declare the
`lma_collector::elasticsearch` class:

```puppet
class { 'lma_collector::elasticsearch':
  server => 'example.com',
}
```

### Collect statistics (a.k.a. metrics)

The `lma_collector::collectd::base` sets up collectd and the communication
channel between collectd and Heka. It also sets up a number of standard collect
plugins.

Usage example:

```puppet
class { 'lma_collector::collectd::base':
  processes       => ['influxdb', 'grafana-server', 'hekad', 'collectd'],
  process_matches => [{name => 'elasticsearch', regex => 'java'}]
  read_threads    => 10,
}
```

### Collect OpenStack statistics

To make the collector collect statistics for an OpenStack service declare
the `lma_collector::collectd::openstack` define:

```puppet
lma_collector::collectd::openstack { 'nova':
  user         => 'user',
  password     => 'password',
  tenant       => 'tenant',
  keystone_url => 'http://example.com/keystone',
}
```

This define can be used for the following OpenStack services: nova, cinder,
glance, keystone, and neutron.

Here is another example for neutron:

```puppet
lma_collector::collectd::openstack { 'neutron':
  user         => 'user',
  password     => 'password',
  tenant       => 'tenant',
  keystone_url => 'http://example.com/keystone',
}
```

### Collect OpenStack service statuses

To make the collector collect statuses of OpenStack services declare the
`lma_collector::collectd::openstack_checks` class:

```puppet
class { 'lma_collector::collectd::openstack_checks':
  user         => 'user',
  password     => 'password',
  tenant       => 'tenant',
  keystone_url => 'http://example.com/keystone',
}
```

### Collectd OpenStack service worker statuses

To make the collector collect statuses of workers of an OpenStack service
declare the `lma_collector::collectd::dbi_services` define:

```puppet
lma_collector::collectd::dbi_services { 'nova':
  dbname          => 'nova',
  username        => 'nova',
  password        => 'nova',
  report_interval => 60,
  downtime_factor => 2,
}
```

This define can be used for the following OpenStack services: nova, cinder and
neutron.

### Collect HAProxy statistics

To make the collector collect statistics for HAProxy declare the
`lma_collector::collectd::haproxy` class:

```puppet
class { 'lma_collector::collectd::haproxy':
 socket      => '/var/lib/haproxy/stats',
 # mapping of proxy names to meaningful names to use in metrics names
 proxy_names => {
   'keystone-1' => 'keystone-public-api',
   'keystone-2' => 'keystone-admin-api',
 },
}
```

### Collect RabbitMQ statistics

To make the collector collect statistics for RabbitMQ declare the
`lma_collector::collectd::rabbitmq` class:

```puppet
class { 'lma_collector::collectd::rabbitmq':
}
```

### Collect Memcached statistics

To make the collector collect statistics for Memcached declare the
`lma_collector::collectd::memcached` class:

```puppet
class {'lma_collector::collectd::memcached':
    host => 'localhost',
}
```

### Collect Apache statistics

To make the collector collect statistics for Apache declare the
`lma_collector::collectd::apache` class:

```puppet
class { 'lma_collector::collectd::apache':
}
```

This will collectd Apache statistics from
`http://127.0.0.1/server-status?auto`.

### Collect Nova Hypervisor statistics

To make the collector collect statistics for the Nova hypervisors declare the
`lma_collector::collectd::hypervisor` class:

```puppet
class { 'lma_collector::collectd::hypervisor':
  user         => 'user',
  password     => 'password',
  tenant       => 'tenant',
  keystone_url => 'http://example.com/keystone',
}
```

### Collect Ceph statistics

To make the collector collect statistics for Ceph declare the
`lma_collector::collectd::ceph_mon` class:

```puppet
class { 'lma_collector::collectd::ceph_mon:
}
```

With this the collector will collect information on the Ceph cluster (health,
monitor count, quorum count, free space, ...) and the placement groups.

### Collect Ceph OSD statistics

To make the collector collect Ceph OSD (Object Storage Daemon) performance
statistics declare the `lma_collector::collectd::ceph_osd` class:

```puppet
class { 'lma_collector::collectd::ceph_osd':
}
```

### Collect Pacemaker statistics

To make the collector collect statistics for Pacemaker declare the
`lma_collector::collectd::pacemaker` class:

```puppet
class { 'lma_collector::collectd::pacemaker':
  resources => ['vip__public', 'vip__management'],
}
```

### Collect MySQL statistics

To make the collector collect statistics for MySQL declare the
`lma_collector::collectd::mysql` class:

```puppet
class { 'lma_collector::collectd::mysql':
  username => 'mysql_username',
  password => 'mysql_password',
}
```

### Collect OpenStack notifications

To make the collector collect notifications emitted by the OpenStack services
declare the `lma_collector::notifications::input` class:

```puppet
class { 'lma_collector::notifications::input':
  topic    => 'lma_notifications',
  host     => '127.0.0.1',
  user     => 'rabbit_user',
  password => 'rabbit_password',
}
```

### Store metrics into InfluxDB

To make the collector store the collected metrics into InfluxDB declare the
`lma_collector::influxdb` class:

```puppet
class { 'lma_collector::influxdb':
  database => 'lma',
  user     => 'lma',
  password => 'secret',
  server   => 'example.com',
}
```

### Send AFD messages to Nagios

To make the collector send AFD messages to Nagios declare the
`lma_collector::afd_nagios` define:

```puppet
lma_collector::afd_nagios { 'node_afds':
  url      => 'http://nagios.example.com/cgi-bin/cmd.cgi',
  user     => 'nagiosadmin',
  password => 'secret',
}
```

### Send GSE messages to Nagios

To make the collector send GSE messages to Nagios declare the
`lma_collector::gse_nagios` define:

```puppet
lma_collector::gse_nagios { 'global_clusters':
  url                       => 'http://nagios.example.com/cgi-bin/cmd.cgi',
  user                      => 'nagiosadmin',
  password                  => 'secret',
  message_type              => 'gse_cluster_metric',
  virtual_hostname          => '00-global_clusters',
  openstack_deployment_name => 'production',
}

```

### Configure the aggregator mode

To make the collector send AFD messages to the aggregator node declare the
`lma_collector::aggregator::client` class:

```puppet
class { 'lma_collector::aggregator::client':
  address => 'aggregator.example.com',
}
```

To make the collector act as an aggregator node for the other collectors
declare the `lma_collector::aggregator::server` class:

```puppet
class { 'lma_collector::aggregator::server':
}
```

## Reference

### Classes

Public Classes:

* [`lma_collector`](#class-lma_collector)
* [`lma_collector::elasticsearch`](#class-lma_collectorelasticsearch)
* [`lma_collector::logs::keystone_wsgi`](#class-lma_collectorlogskeystone_wsgi)
* [`lma_collector::logs::libvirt`](#class-lma_collectorlogslibvirt)
* [`lma_collector::logs::mysql`](#class-lma_collectorlogsmysql)
* [`lma_collector::logs::ovs`](#class-lma_collectorlogsovs)
* [`lma_collector::logs::pacemaker`](#class-lma_collectorlogspacemaker)
* [`lma_collector::logs::rabbitmq`](#class-lma_collectorlogsrabbitmq)
* [`lma_collector::logs::system`](#class-lma_collectorlogssystem)
* [`lma_collector::logs::swift`](#class-lma_collectorlogsswift)
* [`lma_collector::logs::aggregated_http_metrics`](#class-lma_collectorlogsaggregated_http_metrics)
* [`lma_collector::collectd::base`](#class-lma_collectorcollectdbase)
* [`lma_collector::collectd::haproxy`](#class-lma_collectorcollectdhaproxy)
* [`lma_collector::collectd::rabbitmq`](#class-lma_collectorcollectdrabbitmq)
* [`lma_collector::collectd::memcached`](#class-lma_collectorcollectdmemcached)
* [`lma_collector::collectd::openstack_checks`](#class-lma_collectorcollectdopenstack_checks)
* [`lma_collector::collectd::apache`](#class-lma_collectorcollectdapache)
* [`lma_collector::collectd::ceph_mon`](#define-lma_collectorcollectdceph_mon)
* [`lma_collector::collectd::ceph_osd`](#define-lma_collectorcollectdceph_osd)
* [`lma_collector::collectd::hypervisor`](#class-lma_collectorcollectdhypervisor)
* [`lma_collector::collectd::pacemaker`](#class-lma_collectorcollectdpacemaker)
* [`lma_collector::collectd::mysql`](#class-lma_collectorcollectdmysql)
* [`lma_collector::influxdb`](#class-lma_collectorinfluxdb)
* [`lma_collector::notifications::input`](#class-lma_collectornotificationsinput)
* [`lma_collector::notifications::metrics`](#class-lma_collectornotificationsmetrics)
* [`lma_collector::aggregator::client`](#class-lma_collectoraggregatorclient)
* [`lma_collector::aggregator::server`](#class-lma_collectoraggregatorserver)
* [`lma_collector::afd::workers`](#class-lma_collectorafdworkers)
* [`lma_collector::gse_policies`](#class-lma_collectorgse_policies)
* [`lma_collector::metrics::heka_monitoring`](#class-lma_collectormetricsheka_monitoring)
* [`lma_collector::smtp_alert`](#class-lma_collectorsmtp_alert)

Private Classes:

* `lma_collector::params`: Provide defaults for the `lma_collector` module
  parameters.

### Defines

* [`lma_collector::heka`](#define-lma_collectorheka)
* [`lma_collector::logs::openstack`](#define-lma_collectorlogsopenstack)
* [`lma_collector::collectd::openstack`](#define-lma_collectorcollectdopenstack)
* [`lma_collector::afd_filter`](#define-lma_collectorafd_filter)
* [`lma_collector::afd_nagios`](#define-lma_collectorafd_nagios)
* [`lma_collector::gse_cluster_filter`](#define-lma_collectorgse_cluster_filter)
* [`lma_collector::gse_nagios`](#define-lma_collectorgse_nagios)

#### Class: `lma_collector`

Install the common Lua modules used by LMA collectors.

##### Parameters

* `tags`: *Optional*. Fields added to Heka messages. Valid options: a hash. Default: `{}`.

#### Class: `lma_collector::elasticsearch`

Declare this class to make Heka serialize the log messages and send them to
Elasticsearch for indexing.

##### Parameters

* `server`: *Required*. Elasticsearch server name. Valid options: a string.
* `port`: *Required*. Elasticsearch service port. Valid options: an integer.
* `flush_interval`: *Optional*. Interval at which accumulated messages should
   be bulk indexed into Elasticsearch, in seconds. Default: `5`.
* `flush_count`: *Optional*. Number of messages that, if processed, will
   trigger them to be bulk indexed into Elasticsearch. Default: `10`.

#### Class: `lma_collector::logs::keystone_wsgi`

Declare this class to create an Heka `logstreamer` that reads Keystone Apache
logs from `/var/log/apache2/keystone_wsgi_*_access.log`.

This class currently assumes the following log configuration in Apache:

```
CustomLog "/var/log/apache2/keystone_wsgi_main_access.log" "%{X-Forwarded-For}i %l %u %t \"%r\" %>s %b %D \"%{Referer}i\" \"%{User-Agent}i\""
```

for Keystone main and:

```
CustomLog "/var/log/apache2/keystone_wsgi_admin_access.log" "%{X-Forwarded-For}i %l %u %t \"%r\" %>s %b %D \"%{Referer}i\" \"%{User-Agent}i\""
```

for Keystone admin.

The class correctly configures the Heka `logstreamer` for the case of
sequential rotating log files, i.e. log files with the following structure:

```
/var/log/apache2/keystone_wsgi_*_access.log
/var/log/apache2/keystone_wsgi_*_access.log.1
/var/log/apache2/keystone_wsgi_*_access.log.2
```

#### Class: `lma_collector::logs::libvirt`

Declare this class to create an Heka `logstreamer` that reads libvirt logs
from `/var/log/libvirt/libvirtd.log`.

#### Class: `lma_collector::logs::mysql`

Declare this class to create an Heka `logstreamer` that reads MySQL logs from
`/var/log/mysql.log`.

#### Class: `lma_collector::logs::ovs`

Declare this class to create an Heka `logstreamer` that reads Open vSwitch logs
from log files located in the `/var/log/openvswitch/` directory.

#### Class: `lma_collector::logs::pacemaker`

Declare this class to create an Heka `logstreamer` that reads Pacemaker logs
from `/var/log/pacemaker.log`.

#### Class: `lma_collector::logs::rabbitmq`

Declare this class to create an Heka `logstreamer` that reads RabbitMQ logs
from log files located in the `/var/log/rabbitmq` directory.

#### Class: `lma_collector::logs::system`

Declare this class to create an Heka `logstreamer` that reads system logs.

Logs are read from following files in `/var/log`: `daemon.log`, `cron.log`,
`haproxy.log`, `kern.log`, `auth.log`, `syslog`, `messages` and `debug`. This
class assumes that Rsyslog is used, with the `RSYSLOG_TraditionalFileFormat`
template.

More specifically, the following syslog patterns are assumed:

```
<%PRI%>%TIMESTAMP% %HOSTNAME% %syslogtag%%msg:::sp-if-no-1st-sp%%msg%\n
```

or

```
'%TIMESTAMP% %HOSTNAME% %syslogtag%%msg:::sp-if-no-1st-sp%%msg%\n'
```

#### Class: `lma_collector::logs::swift`

Declare this class to create an Heka `logstreamer` that reads Swift logs from
a Syslog file.

##### Parameters

* `file_match`: *Required*. The log file name pattern. Example:
  `'swift\.log$'`. Example for a sequential rotating file:
  `'swift\.log\.?(?P<Seq>\d*)$'`. See
  http://hekad.readthedocs.org/en/latest/pluginconfig/logstreamer.html
  for more information.
* `priority`: *Optional*. When using sequential logstreams, the priority
  defines how to sort the log files in order from the slowest to newest.
  Example: `'["^Seq"]'`. See
  http://hekad.readthedocs.org/en/latest/pluginconfig/logstreamer.html
  for more information.
* `log_directory`: *Optional*. The log directory. Default: `/var/log`.

#### Class: `lma_collector::logs::aggregated_http_metrics`

Declare this class to create an Heka filter that derives HTTP metrics from
OpenStack log messages that include HTTP information (method, status and
response time). Response times are aggregated over an interval and the
following statistics are produced: `min`,`max`,`sum`,`count`,`percentile`.

The metric name is `openstack_<service>_http_response_times` where `<service>`
is the OpenStack service name (e.g. "neutron").

##### Parameters

* `hostname`: *Optional*. The hostname. Default: $::hostname factor.
* `interval`: *Optional*. Interval in second used to aggregate metrics. Default: 10.
* `max_timer_inject`: *Optional*. The maximum number of messages allowed to be injected by the sandbox. Default: 10.
* `bulk_size`: *Optional*. The number of metrics embedded by a bulk_metric. Default: 500.
* `percentile`: *Optional*. The percentile. Default: 90.

#### Class: `lma_collector::collectd::base`

Declare this class to set up collectd and the communication channel between
collectd and Heka. The declaration of this class also sets up a number of
standard collectd plugins, namely `logfile`, `cpu`, `disk`, `interface`,
`load`, `memory`, `processes`, `swap`, and `users`.

##### Parameters

* `processes`: *Optional*. The names of processes that the collectd
  `processes` plugin will get statistics for. Valid options: an array of
  strings. Default: `undef`. See
  https://github.com/voxpupuli/puppet-collectd#class-collectdpluginprocesses
  for more information.
* `process_matches`: *Optional*. Name/regex pairs specifying the processes that
  the collectd `processes` plugin will get statistics for. Valid options: an
  array of hashs with two properties, `name` and `regex`. See
  https://github.com/voxpupuli/puppet-collectd#class-collectdpluginprocesses
  for more information.
* `read_threads`: *Optional*. The number of threads used by collectd. Valid
  options: an integer. Default: 5.
* `purge`: *Optional*. Purge the collectd configuration files. Default:
  `false`.

#### Class: `lma_collector::collectd::haproxy`

Declare this class to configure collectd to collect HAProxy statistics. The
collectd plugin used is a Python script.

##### Parameters

* `socket`: *Required*. The path to HAProxy's `stats` Unix socket. E.g.
  `/var/lib/haproxy/stats`. Valid options: a string.
* `proxy_ignore`: *Optional*. The list of proxy names to ignore, i.e. for which
  no metrics will be created. Valid options: an array of strings. Default:
  `[]`.
* `proxy_names`: *Optional*. A mapping of proxy names to meaningful names used
  in metrics names. This is useful when there are meaningless proxy names such
  as "keystone-1" in the HAProxy configuration. Valid options: a hash. Default:
  `{}`.

#### Class: `lma_collector::collectd::rabbitmq`

Declare this class to configure collectd to collect RabbitMQ statistics. The
collectd plugin used is a Python script, which uses the `rabbitmqctl` command
to get statistics from RabbitMQ.

##### Parameters

* `queue`: *Optional*. Collect statistics for specific queue(s), a string that
  starts and ends with a slash is interpreted as a regular expression
  (backslash `\` must be escaped by writing `\\`).
  Valid option: an array of string. Default: `[]`.

#### Class: `lma_collector::collectd::memcached`

Declare this class to configure collectd to collect Memcached statistics.
collectd's native `memcached` plugin is used to collect statistics and a
custom Python plugin is used to check the availability of Memcached server.

##### Parameters

* `host`: *Required*. The Memcached host. Valid options: a string. See
  https://github.com/voxpupuli/puppet-collectd#class-collectdpluginmemcached.
* `Port`: *Optional. The Memcached port. Valid option: an integer.
  Default: `11211`.

#### Class: `lma_collector::collectd::openstack_checks`

Declare this class to configure collectd to collect statuses of OpenStack
services. The collectd plugin used is a Python script.

##### Parameters

* `user`: *Required*. The user to use when querying the OpenStack endpoint.
  Valid options: a string.
* `password`: *Required*. The password to use when querying the OpenStack
  endpoint. Valid options: a string.
* `tenant`: *Required*. The tenant to use when querying the OpenStack endpoint.
  Valid options: a string.
* `keystone_url`: *Required*. The Keystone endpoint URL to use. Valid options:
  a string.
* `timeout`: *Optional*. Timeout in seconds beyond which the collector
  considers that the endpoint doesn't respond. Valid options: an integer.
  Default: 5.
* `pacemaker_master_resource`: *Optional*. Name of the pacemaker resource used
  to determine if the collecting of statistics should be active. This is
  a parameter for advanced users. For this to function the
  [`lma_collector::collectd::pacemaker`](#class-lma_collectorcollectdpacemaker)
  class should be declared, with its `master_resource` parameter set to the
  same value as this parameter. Valid options: a string. Default: `undef`.

#### Class: `lma_collector::collectd::apache`

Declare this class to configure collectd to collect Apache statistics.
collectd's native `apache` plugin is used. The URL used is
`http://${host}/server-status?auto`, where `${host}`  is replaced by the value
provided with the `host` parameter.

##### Parameters

* `host`: *Optional*. The Apache host. Valid options: a string. Default:
  `'127.0.0.1'`.
* `port`: *Optional*. The Apache port. Valid options: a string. Default: `'80'`.

#### Class: `lma_collector::collectd::hypervisor`

Declare this class to configure collectd to collect statistics on Nova
hypervisors. The collectd plugin used is a Python script talking to the
Nova API.

##### Parameters

* `user`: *Required*. The user to use when querying the OpenStack endpoint.
  Valid options: a string.
* `password`: *Required*. The password to use when querying the OpenStack
  endpoint. Valid options: a string.
* `tenant`: *Required*. The tenant to use when querying the OpenStack endpoint.
  Valid options: a string.
* `keystone_url`: *Required*. The Keystone endpoint URL to use. Valid options:
  a string.
* `timeout`: *Optional*. Timeout in seconds beyond which the collector
  considers that the endpoint doesn't respond. Valid options: an integer.
  Default: 5.
* `pacemaker_master_resource`: *Optional*. Name of the pacemaker resource used
  to determine if the collecting of statistics should be active. This is
  a parameter for advanced users. For this to function the
  [`lma_collector::collectd::pacemaker`](#class-lma_collectorcollectdpacemaker)
  class should be declared, with its `master_resource` parameter set to the
  same value as this parameter. Valid options: a string. Default: `undef`.

#### Class: `lma_collector::collectd::pacemaker`

Declare this class to configure collectd to collect statistics for Pacemaker
resources running on the node. The collectd plugin used is a Python script,
which uses Pacemaker's `crm_resource` command to get statistics from Pacemaker.

##### Parameters

* `resources`: *Required*. The Pacemaker resources to get statistics for. Valid
  options: an hash of strings.
* `notify_resource`: *Optional*. If this is set, the collectd plugin generates
  a collectd notification reporting the state of the Pacemaker resource
  identified to by `master_resource`. Users of
  [`lma_collector::collectd::openstack`](#define-lma_collectorcollectdopenstack),
  [`lma_collector::collectd::openstack_checks`](#class-lma_collectorcollectdopenstackchecks) and
  [`lma_collector::collectd::hypervisor`](#class-lma_collectorcollectdhypervisor)
  with the `notify_resource` parameter needs to declare the
  `lma_collector::collectd::pacemaker` class and use that parameter.
  Valid options: a string. Default: `undef`.
* `hostname`: *Optional*. If this is set it will be used to identify the local
  host in the Pacemaker cluster. If unset, collectd will use the value returned
  by the Python socket.getfqdn() function.
  Valid options: a string. Default: `undef`.

#### Class: `lma_collector::collectd::mysql`

Declare this class to configure collectd to collect statistics for the MySQL
instance local to the node.

The collectd plugin used is the native collectd [MySQL
plugin](https://collectd.org/wiki/index.php/Plugin:MySQL). It is configured
with `'localhost'` as the `Host`, meaning that the local MySQL Unix socket will
be used to connect to MySQL.

##### Parameters

* `username`: *Required*. The database user to use to connect to the MySQL
  database. Valid options: a string.
* `password`: *Required*. The database password to use to connect to the MySQL
  database. Valid options: a string.
* `host`: *Optional*. The IP address to use to connect to the MySQL database.
   Valid options: a string. Default: `localhost`.
* `socket`: *Optional*. The Unix socket to use to  connect to the MySQL database.
   Valid options: a string. Default: `undef`.

#### Class: `lma_collector::collectd::ceph_mon`

Declare this class to make collectd collect Ceph statistics.

With this the collector will collect information on the Ceph cluster (health,
monitor count, quorum count, free space, ...) and the Placement Groups.

The collectd plugin used is a Python script. That script uses the `ceph`
command internally. So for this plugin to work the `ceph` command should be
installed, and a valid configuration for accessing the Ceph cluster should be
in place.

#### Class: `lma_collector::collectd::ceph_osd`

Declare this class to make collectd collect Ceph OSD (Object Storage Daemon)
performance statistics of all the OSD daemons running on the host.

The collectd plugin used is a Python script. That script uses the `ceph`
command internally, so that command should be installed.

#### Class: `lma_collector::influxdb`

Declare this class to make Heka serialize the metric messages and send them to
InfluxDB.

##### Parameters

* `database`: *Required*. InfluxDB database. Valid options: a string.
* `user`: *Required*. InfluxDB username. Valid options: a string.
* `password`: *Required*. InfluxDB password. Valid options: a string.
* `server`: *Required*. InfluxDB server name. Valid options: a string.
* `port`: *Required*. InfluxDB service port. Valid options: an integer.
* `tag_fields`: *Optional*. List of message fields to be stored as tags. Valid
  options: an array. Default: `[]`.
* `time_precision`: *Optional*. Time precision. Valid options: a string.
  Default: `ms`.
* `flush_count`: *Optional*. Maximum number of datapoints to send in a single
  write request. Valid values: an integer. Default: `5000`.
* `flush_interval`: *Optional*. Maximum number of seconds to wait before
  writing data to InfluxDB. Valid values: an integer. Default: `5`.

#### Class: `lma_collector::notifications::input`

Declare this class to make Heka collect the notifications emitted by the
OpenStack services on RabbitMQ.

The OpenStack services should be configured to send their notifications to the
same topic exchange as the one this class is configured with.

##### Parameters

* `topic`: *Required*. The topic exchange from where to read the notifications.
  Valid options: a string.
* `host`: *Required*. The address of the RabbitMQ host. Valid options: a
  string.
* `port`: *Optional*. The port the RabbitMQ host listens on. Valid options:
  an integer. Default: `5672`.
* `user`: *Required*. The user to use to connect to RabbitMQ. Valid options: a
  string.
* `password`: *Required*. The password to use to connect to RabbitMQ.  Valid
  options: a string.

#### Class: `lma_collector::notifications::metrics`

Declare this class to make Heka emit metrics from the OpenStack notifications.

#### Class: `lma_collector::aggregator::client`

Declare this class to make Heka send the AFD messages to another Heka node
running the aggregator service.

##### Parameters

* `address`: *Required*. The address of the aggregator server. Valid options: a
  string.
* `port`: *Optional*. The port the aggregator server listens on. Valid options:
  an integer. Default: `5565`.

#### Class: `lma_collector::aggregator::server`

Declare this class to make Heka run the aggregator service.

##### Parameters

* `listen_address`: *Optional*. The address the aggregator service listens on.
  Valid options: a string. Default: `127.0.0.1`.
* `port`: *Optional*. The port the aggregator service listens on. Valid options:
  an integer. Default: `5565`.
* `http_check_port`: *Optional*. The HTTP port that an external service can use
  to check the health of the aggregator service. Valid options: an integer.
  Default: `undef`.

#### Class: `lma_collector::afd::workers`

Declare this class to configure the Heka filter that sends AFD metrics
reporting the availability of the Neutron agents and the Cinder and Nova
services.

#### Class: `lma_collector::gse_policies`

Declare this class to configure the GSE cluster policies on the aggregator node.

##### Parameters

* `policies`: *Required*. Definition of the GSE cluster policies as described
  in the [Cluster Policies](http://fuel-plugin-lma-collector.readthedocs.org/en/latest/alarms.html#cluster-policies)
  documentation. Valid options: a hash.

#### Class: `lma_collector::metrics::heka_monitoring`

Declare this class to collect metrics for the Heka services themselves.

##### Parameters

* `dashboard_address`: *Optional*. The address Heka dashboards listen on.
  Valid options: a string. Default: `127.0.0.1`.
* `metric_dashboard_port`: *Optional*. The port the Heka dashboard of
  metric collector listens on.
  Valid options: a string. Default: `4353`.
* `log_dashboard_port`: *Optional*. The port the Heka dashboard of
  log collector listens on.
  Valid options: a string. Default: `4352`.

#### Class: `lma_collector::smtp_alert`

Declare this class to send by email the alert notifications based on the GSE
metrics.

##### Parameters

* `send_from`: *Required*. Sender email address. Valid options: a string.
* `send_to`: *Required*. List of recipient email addresses. Valid options: an array.
* `subject`: *Required*. Email subject. Valid options: a string. Default: `LMA
  Alert Notification`.
* `host`: *Optional*. SMTP server address and port. Valid options: a string.
  Default: `127.0.0.1:25`.
* `auth`: *Optional*. SMTP authentication method. Valid options: `none`,
  `Plain` or `CRAMMD5`.  Default: `none`.
* `user`: *Optional*. SMTP username. Valid options: a string. Default: `undef`.
* `password`: *Optional*. SMTP Password. Valid options: a string. Default: `undef`.
* `send_interval`: *Optional*. Minimum time interval in seconds between each
  email. Valid options: an integer. Default: `0`.

#### Define: `lma_collector::heka`

Main Define. Install and configure the Log and Metric collector.
The title must be either `log_collector` or `metric_collector`.

##### Parameters

* `user`: *Optional*. User the Heka service is run as. You may have to use `'root'` on some systems for the Heka service to be able to access log files, run additional commands, ... Valid options: a string.  Default: `'heka'`.
* `groups`: *Optional*. Additional groups to add to the user running the Heka service. Ignored if the Heka service is run as "root". Valid options: an array of strings. Default: `['syslog', 'adm']`.
* `poolsize`: *Optional*. The pool size of maximum messages that can exist (default: 100).
* `heka_monitoring`: *Optional*. Enable the hekad plugins monitoring by configuring
  the Heka dashboard and a filter plugin. Valid options: boolean. Default: true.
* `install_init_script`: *Optional*. Whether or not install the init script (Upstart or Systemd).
  This is typically used when the service is managed by Pacemaker for example.
  Valid options: boolean. Default: true.
* `version`: *Optional*. The Heka version to install. Default: 'latest'.

#### Define: `lma_collector::logs::openstack`

Declare this type to create an Heka `logstreamer` that reads logs of an
OpenStack service.

It works for "standard" OpenStack services that write their logs into log files
located in `/var/log/{service}`, where `{service}` is the service name.

For example it works for Nova, Neutron, Cinder, Glance, Heat, Keysone, Horizon
and Murano.

The define doesn't work for Swift, as Swift only writes its logs to Syslog.
See the specific [`lma_collector::logs::swift`](#class-lma_collectorlogsswift)
class for Swift.

##### Parameters

* `service_match`: *Optional*. The regular expression portion which matches the
  log file names excluding the suffix `.log`. This is generally used to
  explicitly specify the file name(s) within the directory.
  Valid options: a regexp string supported by the [Go programming
  language](https://golang.org/pkg/regexp/). Default: `.+`.

#### Define: `lma_collector::collectd::openstack`

Declare this define to make collectd collect statistics from an OpenStack
service endpoint.

This define supports the following services: nova, cinder, glance, keystone and
neutron.

The resource title should be set to the service name (e.g. `'nova'`).

##### Parameters

* `user`: *Required*. The user to use when querying the OpenStack endpoint.
  Valid options: a string.
* `password`: *Required*. The password to use when querying the OpenStack
  endpoint. Valid options: a string.
* `tenant`: *Required*. The tenant to use when querying the OpenStack endpoint.
  Valid options: a string.
* `keystone_url`: *Required*. The Keystone endpoint URL to use. Valid options:
  a string.
* `timeout`: *Optional*. Timeout in seconds beyond which the collector
  considers that the endpoint doesn't respond. Valid options: an integer.
  Default: 20.
* `max_retries`: *Optional*. Number of maximum retries when an error occurs
  (including timeout). Valid options: an integer.
  Default: 2.
* `pacemaker_master_resource`: *Optional*. Name of the pacemaker resource used
  to determine if the collecting of statistics should be active. This is
  a parameter for advanced users. For this to function the
  [`lma_collector::collectd::pacemaker`](#class-lma_collectorcollectdpacemaker)
  class should be declared, with its `master_resource` parameter set to the
  same value as this parameter. Valid options: a string. Default: `undef`.

#### Define `lma_collector::collectd::dbi_services`

Declare this define to make collectd collect the statuses (`up`, `down` or
`disabled`) of the various workers of an OpenStack service.

The collectd plugin used is DBI, which is a native collectd plugin. That plugin
uses SQL queries to the MySQL database.

This define supports the following services: nova, cinder, and neutron.

The resource title should be set to the service name (e.g. `'nova'`).

##### Parameters

* `dbname`: *Required*. The database name. Valid options: a string.
* `username`: *Required*. The database user. Valid options: a string.
* `password`: *Required*. The database password. Valid options: a string.
* `hostname`: *Optional*. The database hostname. Valid options: a string.
  Default: `'localhost'`.
* `report_interval`: *Required*. The report interval in seconds used in the
  service configuration. For example Nova's current default value is 10.
  Valid options: an integer.
* `downtime_factor`: *Required*. The downtime factor used to determine when
  consider a worker is down. A service is deemed "down" if no heartbeat has
  been received since `downtime_factor * report_interval` seconds. Valid
  options: an integer.

#### Define `lma_collector::afd_filter`

Declare this define to configure an [Anomaly and Fault Detection
filter](http://fuel-plugin-lma-collector.readthedocs.org/en/latest/alarms.html)
in Heka.

##### Parameters

* `type`: *Required*. Type of the AFD filter. Valid options: either `service`
  for service AFD filters or `node` for node AFD filters.
* `cluster_name`: *Required*. Value of the `service` field (for service AFD
  filters) or `node_role` (for node AFD filters) for the messages emitted by
  the filter. Valid options: a string.
* `logical_name`: *Required*. Value of the `source` field for the messages
  emitted by the filter. Valid options: a string.
* `alarms`: *Required*. List of alarm rules enabled for this filter. Valid
  options: an array.
* `alarms_definitions`: *Required*. List of the alarm rules definitions. Valid
  options: an array.
* `message_matcher`: *Required*. Message matcher for the Heka filter. Valid
  options: a string.

#### Define `lma_collector::afd_nagios`

Declare this define to send [Anomaly and Fault Detection messages](
http://fuel-plugin-lma-collector.readthedocs.org/en/latest/alarms.html)
to Nagios as [passive check
results](https://assets.nagios.com/downloads/nagioscore/docs/nagioscore/3/en/passivechecks.html).

##### Parameters

* `url`: *Required*. URL to the Nagios cgi.bin script. Valid options: a
  string.
* `user`: *Optional*. Username used to authenticate to the Nagios web
  interface. Valid options: a string. Default: `nagiosadmin`.
* `password`: *Optional*. Password used to authenticate to the Nagios web
  interface. Valid options: a string. Default: empty string.
* `hostname`: *Optional*. It must match the hostname configured in Nagios.
  Valid options: a string. Default: `$::hostname`.
* `service_template`: *Optional*. It must match the service description
  configured in Nagios. Supports interpolation of message field values. Valid
  options: a string. Default: `%{node_role}.%{source}`.
* `message_type`: *Optional*. Type of AFD messages to send to Nagios. Valid
  options: a string. Default: `afd_node_metric`.

#### Define `lma_collector::gse_cluster_filter`

Declare this define to configure an [Global Status Evaluation filter](
http://fuel-plugin-lma-collector.readthedocs.org/en/latest/alarms.html)
in Heka.

##### Parameters

* `input_message_types`: *Required*. Message types that the GSE filter should
  process. Valid options: an array.
* `aggregator_flag`: *Required*. Whether or not the GSE filter receives messages
  emitted by the collectors or the aggregator itself. Valid options: a boolean.
* `member_field`: *Required*. Field in the input messages used by the GSE filter
  to identify the cluster members. Valid options: a string.
* `output_message_type`: *Required*. Type of messages emitted by the GSE
  filter. Valid options: a string.
* `output_metric_name`: *Required*. Metric name for the messages emitted by the
  GSE filter. Valid options: a string.
* `interval`: *Optional*. Interval (in seconds) at which the GSE filter emits
  its metric messages. Valid options: an integer. Default: 10.
* `cluster_field`: *Optional*. Field in the input message used by the GSE
  filter to associate the AFD/GSE metrics to the clusters. Valid options: a
  string. Default: undef.
* `clusters`: *Optional*. List of clusters that the plugin manages. See the [GSE
  configuration](http://fuel-plugin-lma-collector.readthedocs.org/en/latest/alarms.html)
  documentation for details. Valid options: a hash. Default: {}.
* `warm_up_period`: *Optional*. Number of seconds after a (re)start that the
  GSE plugin will wait before emitting its metric messages. Valid options: an
  integer. Default: undef.
* `enable_notification`: *Optional*. Whether or not enable notifications in the
  alerting system. Valid options: a boolean. Default: true.
* `activate_alerting`: *Optional*. Whether or not configure alerting system
  for all clusters. Valid options: a boolean. Default: true.

#### Define `lma_collector::gse_nagios`

Declare this define to send [Global Status Evaluation messages](
http://fuel-plugin-lma-collector.readthedocs.org/en/latest/alarms.html)
to Nagios as [passive check
results](https://assets.nagios.com/downloads/nagioscore/docs/nagioscore/3/en/passivechecks.html).

##### Parameters

* `url`: *Required*. URL to the Nagios cgi.bin script. Valid options: a
  string.
* `user`: *Optional*. Username used to authenticate to the Nagios web
  interface. Valid options: a string. Default: `nagiosadmin`.
* `password`: *Optional*. Password used to authenticate to the Nagios web
  interface. Valid options: a string. Default: empty string.
* `service_template`: *Optional*. It must match the service description
  configured in Nagios. Supports interpolation of message field values. Valid
  options: a string. Default: `%{cluster_name}`.
* `message_type`: *Required*. Type of GSE messages to send to Nagios. Valid
  options: a string.
* `virtual_hostname`: *Required*. The host configured in Nagios to receive the
  GSE checks must be named "${virtual_hostname}-env${openstack_deployment_name}".
  Valid options: a string.
* `openstack_deployment_name`: *Optional*. Additional label to identify the
  environment.  Valid options: a string. Default: empty string.

Limitations
-----------


License
-------

Licensed under the terms of the Apache License, version 2.0.

Contact
-------

Simon Pasquier, <spasquier@mirantis.com>

Support
-------

See the Contact section.
