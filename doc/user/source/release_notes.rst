.. _release_notes:

.. raw:: latex

   \pagebreak

Release notes
-------------

Version 0.10.2
++++++++++++++

The StackLight Collector plugin 0.10.2 for Fuel contains the following updates:

* Implemented the capability for the Elasticsearch bulk size to increase when
  required. See `#1617211 <https://bugs.launchpad.net/lma-toolchain/+bug/1617211>`_.

* Fixed the issue with the OCF script installation. See
  `#1575039 <https://bugs.launchpad.net/lma-toolchain/+bug/1575039>`_.

* Updated the documentation with new definitions for
  ``memcached_ps_cputime_syst`` and ``memcached_ps_cputime_user``. See
  `#1576265 <https://bugs.launchpad.net/lma-toolchain/+bug/1576265>`_.

Version 0.10.1
++++++++++++++

The StackLight Collector plugin 0.10.1 for Fuel contains the following updates:

* Fixed Elasticsearch address for collectd when using network templates. See
  `#1614944 <https://bugs.launchpad.net/lma-toolchain/+bug/1614944>`_.

* Fixed InfluxDB address for collectd when using network templates. See
  `#1614945 <https://bugs.launchpad.net/lma-toolchain/+bug/1614945>`_.

* Updated the documentation regarding the post-deployment of StackLight. See
  `#1611156 <https://bugs.launchpad.net/lma-toolchain/+bug/1611156>`_.

* Fixed concurrent execution of logrotate. See
  `#1455104 <https://bugs.launchpad.net/lma-toolchain/+bug/1455104>`_.

Version 0.10.0
++++++++++++++

Additionally to the bug fixes, the StackLight Collector plugin 0.10.0 for Fuel
contains the following updates:

* Separated the processing pipeline for logs and metrics.

  Prior to StackLight version 0.10.0, there was one instance of the *hekad*
  process running to process both the logs and the metrics. Starting with
  StackLight version 0.10.0, the processing of the logs and notifications is
  separated from the processing of the metrics in two different *hekad*
  instances. This allows for better performance and control of the flow when
  the maximum buffer size on disk has reached a limit. With the *hekad*
  instance processing the metrics, the buffering policy mandates to drop the
  metrics when the maximum buffer size is reached. With the *hekad* instance
  processing the logs, the buffering policy mandates to block the entire
  processing pipeline. This helps to avoid losing logs (and notifications)
  when the Elasticsearch server is inaccessible for a long period of time.
  As a result, the StackLight collector has now two processes running
  on the node:

  * One for the *log_collector* service
  * One for the *metric_collector* service

* The metrics derived from logs are now aggregated by the *log_collector*
  service.

  To avoid flooding the *metric_collector* with bursts of metrics derived from
  logs, the *log_collector* service sends metrics by bulk to the
  *metric_collector* service. An example of aggregated metric derived from
  logs is the `openstack_<service>_http_response_time_stats
  <http://fuel-plugin-lma-collector.readthedocs.io/en/latest/appendix_b.html#api-response-times>`_.

* Added a diagnostic tool.

  A diagnostic tool is now available to help diagnose issues. The diagnostic
  tool checks that the toolchain is properly installed and configured across
  the entire LMA toolchain. For more information, see
  :ref:`Diagnostic tool <diagnostic>`.

Version 0.9.0
+++++++++++++

The StackLight Collector plugin 0.9.0 for Fuel contains the following updates:

 * Upgraded to Heka *0.10.0*.

 * Added the capability to collect libvirt metrics on compute nodes.

 * Added the capability to detect spikes of errors in the OpenStack services
   logs.

 * Added the capability to report OpenStack workers status per node.

 * Added support for multi-environment deployments.

 * Added support for Sahara logs and notifications.

* Bug fixes:

  * Added the capability to reconnect to the local RabbitMQ instance if the
    connection has been lost.
    See `#1503251 <https://bugs.launchpad.net/lma-toolchain/+bug/1503251>`_.

  * Enabled buffering for Elasticsearch, InfluxDB, Nagios and TCP outputs to
    reduce congestion in the Heka pipeline.
    See `#1488717 <https://bugs.launchpad.net/lma-toolchain/+bug/1488717>`_,
    `#1557388 <https://bugs.launchpad.net/lma-toolchain/+bug/1557388>`_.

  * Fixed the status for Nova when Midonet is used.
    See `#1531541 <https://bugs.launchpad.net/lma-toolchain/+bug/1531541>`_.

  * Fixed the status for Neutron when Contrail is used.
    See `#1546017 <https://bugs.launchpad.net/lma-toolchain/+bug/1546017>`_.

  * Increased the maximum number of file descriptors.
    See `#1543289 <https://bugs.launchpad.net/lma-toolchain/+bug/1543289>`_.

  * The spawning of several hekad processes is now avoided.
    See `#1561109 <https://bugs.launchpad.net/lma-toolchain/+bug/1561109>`_.

  * Removed the monitoring of individual queues of RabbitMQ. See `#1549721
    <https://bugs.launchpad.net/lma-toolchain/+bug/1549721>`_.

  * Added the capability to rotate hekad logs every 30 minutes if necessary.
    See `#1561603 <https://bugs.launchpad.net/lma-toolchain/+bug/1561603>`_.

Version 0.8.0
+++++++++++++

The StackLight Collector plugin 0.8.0 for Fuel contains the following updates:

* Added support for alerting in two different modes:

  * Email notifications

  * Integration with Nagios

* Upgraded to InfluxDB 0.9.5.

* Upgraded to Grafana 2.5.

* Management of the LMA collector service by Pacemaker on the controller nodes
  for improved reliability.

* Monitoring of the LMA toolchain components (self-monitoring).

* Added support for configurable alarm rules in the Collector.


Version 0.7.0
+++++++++++++

The initial release of the StackLight Collector plugin. This is a beta version.
