.. _user_overview:

Overview
========

The LMA Collector is best described as a pluggable message processing and
routing pipeline. Its core components are:

* `collectd <https://collectd.org/>`_ that is bundled with a collection of
  monitoring plugins. Many of them are purpose-built for OpenStack.
* `Heka <https://github.com/mozilla-services/heka>`_ that is written in Go is
  the cornerstone component of the Collector.  Heka supports out-of-the-box a
  number of input and output plugins that allows to integrate the Collector
  with a number of external systems using their native protocol like
  Elasticsearch, InfluxDB, Nagios, SMTP, Whisper, Kafka, AMQP and Carbon to
  name a few.
* A collection of Heka plugins written in Lua to decode and process the
  acquired operational data that are then sent to external systems for further
  processing.

The Collector is installed on every OpenStack node by the Fuel plugin. Its role
is to gather all operational data that we think are relevant to increase the
operational visibility of an OpenStack environment. Those data are collected
from a variety of sources including log files, collectd, and RabbitMQ for the
OpenStack notifications. The Collector which runs on the active controller node
of the Mirantis OpenStack HA cluster is called the Aggregator because it
performs additional aggregation and correlation functions to detect service
availability problems.

Another important function of the Collector is to transform raw data into
internal message representations that are based on the Heka message structure
which can be matched and filtered to, for example, create new metrics that can
be routed to a specific destination using simple matching rules. For example,
messages extracted from the OpenStack notifications are filtered and processed
to create new metrics like the creation time of an instance or volume.

.. _plugin_requirements:

Requirements
------------

+-------------------------------------------------------+-----------------------------------------------------------------+
| Requirement                                           | Version/Comment                                                 |
+=======================================================+=================================================================+
| Mirantis OpenStack                                    | 7.0                                                             |
+-------------------------------------------------------+-----------------------------------------------------------------+
| A running Elasticsearch server (for log analytics)    | 1.4 or higher, the RESTful API must be enabled over port 9200   |
+-------------------------------------------------------+-----------------------------------------------------------------+
| A running InfluxDB server (for metric analytics)      | 0.9.4 or higher, the RESTful API must be enabled over port 8086 |
+-------------------------------------------------------+-----------------------------------------------------------------+
| A running Nagios server (for infrastructure alerting) | 3.5 or higher, the command CGI must be enabled                  |
+-------------------------------------------------------+-----------------------------------------------------------------+

Limitations
-----------

The plugin is only compatible with OpenStack environments deployed with Neutron
as the networking configuration.
