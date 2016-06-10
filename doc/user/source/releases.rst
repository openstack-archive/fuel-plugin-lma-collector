.. _releases:

Release Notes
=============

Version 0.10.0
--------------

* Changes

  * Separate processing pipeline for logs and metrics

    Prior to StackLight version 0.10.0, there was one instance of the *hekad*
    process running to process both the logs and the metrics. Starting with StackLight
    version 0.10.0, the processing of logs and notifications is separated
    from the processing of metrics into two different *hekad* instances.
    This allows for better performance and flow control mechanisms when the
    maximum buffer size on disk has reached a limit. With the *hekad* instance
    processing the metrics, the buffering policy mandates to drop the metrics
    when the maximum buffer size is reached. With the *hekad* instance
    processing the logs, the buffering policy mandates to block the
    entire processing pipeline. This way, one can avoid
    loosing logs (and notifications) in cases when the Elasticsearch
    server has been inaccessible for a long period of time.
    As a result, the StackLight collector has now two services running
    on a node:

    * The **log_collector** service
    * The **metric_collector** service

  * Metrics derived from logs are now aggregated

    To avoid flooding the *metric_collector* with bursts of metrics derived
    from logs, the *log_collector* service sends aggregated metrics
    by bulk to the *metric_collector* service.
    An example of aggregated metric derived from logs is the
    `openstack_<service>_http_response_time_stats
    <http://fuel-plugin-lma-collector.readthedocs.io/en/latest/appendix_b.html#api-response-times>`_.

  * Diagnostic tool

    A diagnostic tool is now available to help diagnose problems.
    The diagnostic tool checks that the toolchain is properly installed
    and configured across the entire StackLight LMA toolchain. Please check the
    the `Troubleshooting Chapter
    <http://fuel-plugin-lma-collector.readthedocs.io/en/latest/configuration.html#troubleshooting>`_
    of the User Guide for more information.

* Bug fixes

Version 0.9.0
-------------

* Changes

  * Upgrade to Heka *0.10.0*.

  * Collect libvirt metrics on compute nodes.

  * Detect spikes of errors in the OpenStack services logs.

  * Report OpenStack workers status per node.

  * Support multi-environment deployments.

  * Add support for Sahara logs and notifications.

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

  * Avoid spawning several hekad processes (`#1561109
    <https://bugs.launchpad.net/lma-toolchain/+bug/1561109>`_).

  * Remove the monitoring of individual queues of RabbitMQ (`#1549721
    <https://bugs.launchpad.net/lma-toolchain/+bug/1549721>`_).

  * Rotate hekad logs every 30 minutes if necessary (`#1561603
    <https://bugs.launchpad.net/lma-toolchain/+bug/1561603>`_).

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
