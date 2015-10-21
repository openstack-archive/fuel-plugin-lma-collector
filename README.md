Logging, Monitoring and Alerting (LMA) Collector Plugin for Fuel
================================================================

The Logging, Monitoring & Alerting (LMA) *Collector* is a kind of advanced
monitoring agent that should be installed on each of the OpenStack nodes
you want to monitor.
The Collector is a key component of the LMA Toolchain since it is
individually responsible for supporting all the sensing, measurement,
collection, analysis and computation functions for the node it is running on.

A wealth of  operational data are collected from a variety of sources including
the log files, collectd and RabbitMQ for the OpenStack notifications.
The Collector, which runs on the active controller of the control plane cluster, is
called the *Aggregator* because it performs additional aggregation and
multivariate correlation functions to compute service healthiness metrics at
the cluster level.
An important function of the Collector is to sanitize and transform the ingested
raw operational data into internal messages which uses the Heka
message structure. This structure is used to match, filter and route certain
types of messages to plugins written in Lua which perform the analysis and
computation functions of the toolchain.

It’s main building blocks are:

* collectd which is bundled with a collection of standard and purpose-built
plugins for OpenStack.
* Heka which is the swiss army knife we use for data processing.
* A collection of Heka plugins written in Lua.

There are three types of Lua plugins running in the LMA Collector / Aggregator:

* The input plugins to collect, decode, and sanitize the operational data that
  are transformed into internal messages which in turn are injected into the
  Heka pipeline.
* The filter plugins to execute the alarms, the anomaly detection logic
  and the correlation functions.
* The output plugins to encode and transmit the messages to external systems like
  Elasticsearch, InfluxDB or Nagios where the information is persisted or further processed.

The output of the Collector / Aggregator is of four kinds:

* The logs and notifications that are sent to Elasticsearch for indexing.
  Elasticsearch combined with Kibana provides an insightful log analytic dashboards.
* The metrics which are sent to InfluxDB.
  InfluxDB combined with Grafana provides insightful time-series analytic dashboards.
* The health status checks that are sent to Nagios (or through SMTP) for all the OpenStack
  services and clusters of nodes.
* The annotation messages that are sent to InfluxDB. The annotation messages contain
  information about what caused a cluster of services or a cluster of nodes to change a state.
  The annotation messages provide root cause analysis hints whenever possible.
  The annotation messages are also used to construct the alert notifications sent via SMTP.

Please check the [LMA Collector Plugin for Fuel
](http://fuel-plugin-lma-collector.readthedocs.org/en/latest/index.html)
documentation for additional details.

Release Notes
-------------

**0.8.0**

* Support for alerting in two different modes:
  * Email notifications.
  * Integration with Nagios.
* Upgrade to InfluxDB 0.9.4.
* Upgrade to Grafana 2.1
* Management of the LMA collector service by Pacemaker on the controller nodes
  for improved reliability.
* Monitoring of the LMA toolchain components (self-monitoring).
* Support for configurable alarm rules in the Collector.

**0.7.0**

* Initial release of the plugin. This is a beta version.

Requirements
------------

The plugin's requirements are defined in the [LMA Collector Plugin Documentation](
http://fuel-plugin-lma-collector.readthedocs.org/en/latest/user/overview.html#requirements)

Known issues
------------

No known issues so far.

Limitations
-----------

The plugin is only compatible with OpenStack environments deployed with Neutron
for networking.

Installation Guide
------------------

Please follow the installation instructions of the [LMA Collector Plugin Documentation](
http://fuel-plugin-lma-collector.readthedocs.org/en/latest/user/installation.html#installation)


User Guide
----------

How to configure and use the plugin is detailed in the [The LMA Collector Plugin Documentation](
http://fuel-plugin-lma-collector.readthedocs.org/en/latest/user/guide.html#user-guide)

Communication
-------------

The *OpenStack Development Mailing List* is the preferred way to communicate
with the members of the project.
Emails should be sent to `openstack-dev@lists.openstack.org` with the subject
prefixed by `[fuel][plugins][lma]`.


Reporting Bugs
--------------

Bugs should be filled on the [Launchpad fuel-plugins project](
https://bugs.launchpad.net/fuel-plugins) (not GitHub) with the tag `lma`.

Contributing
------------

If you would like to contribute to the development of this Fuel plugin you must
follow the [OpenStack development workflow](
http://docs.openstack.org/infra/manual/developers.html#development-workflow).

Patch reviews take place on the [OpenStack gerrit](
https://review.openstack.org/#/q/status:open+project:openstack/fuel-plugin-lma-collector,n,z)
system.

Contributors
------------

* Guillaume Thouvenin <gthouvenin@mirantis.com>
* Patrick Petit <ppetit@mirantis.com>
* Simon Pasquier <spasquier@mirantis.com>
* Swann Croiset <scroiset@mirantis.com>
