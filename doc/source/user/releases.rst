.. _releases:

Release Notes
=============

Version 0.9.0
-------------

* Collect libvirt metrics on compute nodes.
* Detect spikes of errors in the OpenStack services logs.
* Report OpenStack workers status per node.
* Support multi-environment deployments.
* Several critical bugs fixes
    * 1530326 Heka logstreamer journal missing for OpenStack services
    * 1488717 Controller looses connection to elasticserch/kibana
    * 1503251 The collector service stops when the local RabbitMQ server is down
    * 1535577 Keystone HTTP metrics are missing
    * 1538946 Cluster status metrics are missing

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
