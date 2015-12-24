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

Private Classes:

* `lma_collector::params`: Provide defaults for the `lma_collector` module
  parameters.

### Defines

* [`lma_collector::logs::openstack`](#define-lma_collectorlogsopenstack)

#### Class: `lma_collector`

Main class. Install and configure the main components of the LMA collector.

##### Parameters

* `tags`: *Optional*. Fields added to Heka messages. Valid options: a hash. Default: `{}`.
* `user`: *Optional*. User the Heka service is run as. You may have to use `'root'` on some systems for the Heka service to be able to access log files, run additional commands, ... Valid options: a string.  Default: `'heka'`.
* `groups`: *Optional*. Additional groups to add to the user running the Heka service. Ignored if the Heka service is run as "root". Valid options: an array of strings. Default: `['syslog', 'adm']`.

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
  `'swift\.log$'`.
* `log_directory`: *Optional*. The log directory. Default: `/var/log`.

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
