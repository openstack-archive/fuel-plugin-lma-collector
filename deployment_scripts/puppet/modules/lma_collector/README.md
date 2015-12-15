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

### Configure logging

To make the collector collect logs created by an OpenStack service declare the
`lma_collector::logs::openstack` define. This is an example for the Nova logs:

```puppet
lma_collector::logs::openstack { 'nova': }
```

This configures Heka to read the Nova logs from the log files located in
`/var/log/nova/`.

## Reference

### Classes

Public Classes:

* [`lma_collector`](#class-lma_collector)

Private Classes:

* `lma_collector::params`: Provide defaults for the `lma_collector` module
  parameters.

### Defines

* [`lma_collector::logs::openstack`](#define-lma_collectorlogsopenstack)

#### Class: `lma_collector`

Main class. Install and configure the main components of the LMA collector.

##### Parameters (all optional)

* `tags`: Fields added to Heka messages. Valid options: a hash. Default: `{}`.
* `groups`: Additional groups to add the `heka` user to. Valid options: an array of strings. Default: `['syslog', 'adm', 'keystone']`.

Example:

```puppet
# Configure the common components of the collector service
class {'lma_collector':
  tags => {
    tag_A => 'some value'
  }
}
```

#### Define: `lma_collector::logs::openstack`

Declare this type to create an Heka `logstreamer` that reads logs of an
OpenStack service. The `logstreamer` is automatically configured with an Heka
decoder and an Heka splitter appropriate for OpenStack logs.

It works for "standard" OpenStack services that write their logs into log files
located in `/var/log/{service}`, where `{service}` is the service name.

For example it can be used for Nova, Neutron, Cinder, Glance, Heat, Keysone,
Horizon and Murano.

Example for Neutron:

```puppet
lma_collector:logs::openstack { 'neutron': }
```

Limitations
-----------

This module supports only Fuel-based deployments using Neutron.

License
-------

Licensed under the terms of the Apache License, version 2.0.

Contact
-------

Simon Pasquier, <spasquier@mirantis.com>

Support
-------

See the Contact section.
