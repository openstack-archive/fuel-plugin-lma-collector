.. _releases:

Release Notes
=============

Version 0.8.1
-------------

* Bug fixes

  * Reconnect to the local RabbitMQ instance if the connection has been lost
    (`#1503251 <https://bugs.launchpad.net/lma-toolchain/+bug/1503251>`_).

  * Enable buffering for Elasticsearch, InfluxDB, Nagios and TCP outputs to reduce
    congestion in the Heka pipeline (`#1488717
    <https://bugs.launchpad.net/lma-toolchain/+bug/1488717>`_, `#1557388
    <https://bugs.launchpad.net/lma-toolchain/+bug/1557388>`_).

  * Return the correct status for Nova when Midonet is used (`#1531541
    <https://bugs.launchpad.net/lma-toolchain/+bug/1531541>`_).

  * Return the correct status for Neutron when Contrail is used (`#1546017
    <https://bugs.launchpad.net/lma-toolchain/+bug/1546017>`_).

  * Increase the maximum number of file descriptors (`#1543289
    <https://bugs.launchpad.net/lma-toolchain/+bug/1543289>`_).

  * Avoid spawn several hekad processes (`#1561109
    <https://bugs.launchpad.net/lma-toolchain/+bug/1561109>`_).

* Changes

  * Upgrade to Heka 0.10.0

Version 0.8.0
-------------

* Support for alerting in two different modes:

  * Email notifications.

  * Integration with Nagios.

* Upgrade to InfluxDB 0.9.5.

* Upgrade to Grafana 2.5.

* Management of the LMA collector service by Pacemaker on the controller nodes for improved reliability.

* Monitoring of the LMA toolchain components (self-monitoring).

* Support for configurable alarm rules in the Collector.


Version 0.7.0
-------------

* Initial release of the plugin. This is a beta version.
