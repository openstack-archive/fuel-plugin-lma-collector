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
  log_directory => '/var/log',
  file_match    => 'swift-all\.log$',
}
```

## Reference

### Classes

Public Classes:

* [`lma_collector`](#class-lma_collector)
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
* `groups`: *Optional*. Additional groups to add the `heka` user to. Valid options: an array of strings. Default: `['syslog', 'adm']`.

#### Class `lma_collector::logs::swift`

Declare this class to collect Swift logs from a Syslog file.

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
