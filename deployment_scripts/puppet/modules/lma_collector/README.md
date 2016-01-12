# lma_collector

## Overview

The `lma_collector` module lets you use Puppet to configure and deploy LMA
(Logging, Monitoring and Alerting) collectors.

The LMA collector's main component is [Heka](http://hekad.readthedocs.org).
Heka is used to process log, notification and metric messages, and persist
these messages into Elasticsearch and InfluxDB.

## Usage

### Setup

To install and configure the main components, declare the `lma_collector`
class:

```puppet
class { 'lma_collector': }
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

To make the Collector collect standard system logs from `/var/log/kern.log`,
`/var/log/messages`, etc. declare the `lma_collector::logs::system` class:

```puppet
class { 'lma_collector::logs::system': }
```

### Collect OpenStack logs

To make the collector collect logs created by an OpenStack service declare the
`lma_collector::logs::openstack` define. This is an example for the Nova logs:

```puppet
lma_collector::logs::openstack { 'nova': }
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
the ``lma_collector::collectd::openstack`` define:

```puppet
lma_collector::collectd::openstack { 'nova':
  user         => 'user',
  password     => 'password',
  tenant       => 'tenant',
  keystone_url => 'http://example.com/keystone',
}
```

This class can be used for the following OpenStack services: nova, cinder,
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
``lma_collector::collectd::openstack_checks`` class:

```puppet
class { 'lma_collector::collectd::openstack_checks':
  user         => 'user',
  password     => 'password',
  tenant       => 'tenant',
  keystone_url => 'http://example.com/keystone',
}
```

### Collect HAProxy statistics

To make the collector collect statistics for HAProxy declare the
``lma_collector::collectd::haproxy`` class:

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
``lma_collector::collectd::rabbitmq`` class:

```puppet
class { 'lma_collector::collectd::rabbitmq':
}
```

### Collect Memcached statistics

To make the collector collect statistics for Memcached declare the
``lma_collector::collectd::memcached`` class:

```puppet
class {'lma_collector::collectd::memcached':
    host => 'localhost',
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
* [`lma_collector::collectd::base`](#class-lma_collectorcollectdbase)
* [`lma_collector::collectd::haproxy`](#class-lma_collectorcollectdhaproxy)
* [`lma_collector::collectd::rabbitmq`](#class-lma_collectorcollectdrabbitmq)
* [`lma_collector::collectd::memcached`](#class-lma_collectorcollectdmemcached)
* [`lma_collector::collectd::openstack_checks`](#class-lma_collectorcollectdopenstackchecks)

Private Classes:

* `lma_collector::params`: Provide defaults for the `lma_collector` module
  parameters.

### Defines

* [`lma_collector::logs::openstack`](#define-lma_collectorlogsopenstack)
* [`lma_collector::collectd::openstack`](#define-lma_collectorcollectdopenstack)

#### Class: `lma_collector`

Main class. Install and configure the main components of the LMA collector.

##### Parameters

* `tags`: *Optional*. Fields added to Heka messages. Valid options: a hash. Default: `{}`.
* `groups`: *Optional*. Additional groups to add the `heka` user to. Valid options: an array of strings. Default: `['syslog', 'adm']`.

#### Class: `lma_collector::elasticsearch`

Declare this class to make Heka serialize the log messages and send them to
Elasticsearch for indexing.

##### Parameters

* `server`: *Required*. Elasticsearch server name. Valid options: a string.
* `port`: *Optional*. Elasticsearch service port. Valid options: a string. Default: "9200".

#### Class: `lma_collector::logs::keystone_wsgi`

Declare this class to create an Heka `logstreamer` that reads Keystone Apache
logs from `/var/log/apache2/keystone_wsgi_*_access.log`.

This class currently assumes the following log configuration in Apache:

```
CustomLog "/var/log/apache2/keystone_wsgi_main_access.log" "%h %l %u %t \"%r\" %>s %b %D \"%{Referer}i\" \"%{User-Agent}i\""
```

for Keystone main and:

```
CustomLog "/var/log/apache2/keystone_wsgi_admin_access.log" "%h %l %u %t \"%r\" %>s %b %D \"%{Referer}i\" \"%{User-Agent}i\""
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

Declare this class to create an Heka `logstreamer` that reads system logs. Logs
are read from the following files: `daemon.log`, `cron.log`, `haproxy.log`,
`kern.log`, `auth.log`, `syslog`, `messages` and `debug` (all located in the
`/var/log` directory).

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

#### Class: `lma_collector::collectd::memcached`

Declare this class to configure collectd to collect Memcached statistics.
collectd's native `memcached` plugin is used.

##### Parameters

* `host`: *Required*. The Memcached host. Valid options: a string. See
  https://github.com/voxpupuli/puppet-collectd#class-collectdpluginmemcached.

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
  a parameter for advanced users. Valid options: a string. Default: `undef`.

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

#### Define: `lma_collector::collectd::openstack`

Declare this define to make the collectd collect statistics from an OpenStack
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
  Default: 5.
* `pacemaker_master_resource`: *Optional*. Name of the pacemaker resource used
  to determine if the collecting of statistics should be active. This is
  a parameter for advanced users. Valid options: a string. Default: `undef`.

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
