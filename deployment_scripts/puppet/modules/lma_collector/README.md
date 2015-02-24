LMA collector module for Puppet
===============================

Description
-----------

Puppet module for configuring the Logging, Monitoring and Alerting collector.

Usage
-----

To deploy the LMA collector service on a host and forward collected data to
ElasticSearch and/or InfluxDB servers.

```puppet
# Configure the common components of the collector service
class {'lma_collector':
  tags => {
    tag_A => 'some value'
  }
}

# Collect system logs
class { 'lma_collector::system_logs':
}

# Send data to ElasticSearch
class { 'lma_collector::elasticsearch':
  server => '10.20.0.2'
}
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
