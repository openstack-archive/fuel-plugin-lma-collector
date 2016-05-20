Overview
========

The Mirantis OpenStack LMA (Logging, Monitoring and Alerting) Toolchain is comprised
of a collection of open-source tools to help you monitor and diagnose problems in your
OpenStack environment. These tools are packaged and delivered as `Fuel plugins
<https://wiki.openstack.org/wiki/Fuel/Plugins>`_ you can install from within the
graphic user interface of Fuel starting with Mirantis OpenStack version 6.1.

From a high level view, the LMA Toolchain includes:

* The LMA Collector (or just the Collector) to gather all operational data that we
  think are relevant to increase the **operational visibility** over your OpenStack
  environment. Those data are collected from a variety of sources including the log messages,
  `collectd <https://collectd.org/>`_, and the `OpenStack notifications bus <https://wiki.openstack.org/wiki/SystemUsageData>`_
* Pluggable external systems we call **satellite clusters** which can take action on the
  data received from the Collectors running on the OpenStack nodes.

The Collector is best described as a **pluggable message processing and routing pipeline**.
Its core components are :

* Collectd that is bundled with a collection of monitoring plugins. Many of them are purpose-built
  for OpenStack.
* `Heka <https://github.com/mozilla-services/heka>`_ which is the cornerstone component
  of the Collector.
* A collection of Heka plugins written in Lua to decode, process and encode the data to be sent
  to external systems.

The primary function of the Collector is to transform the acquired raw
operational data into an internal message representation that is based on the
`Heka message structure <http://hekad.readthedocs.io/en/latest/message/index.html>`_.
that can be further exploited to, for example, detect anomalies or create
new metric messages.

The satellite clusters delivered as part of the LMA Toolchain starting with Mirantis OpenStack 6.1 include:

* `Elasticsearch <http://www.elasticsearch.org/>`_, a powerful open source search server based
  on Lucene and analytics engine that makes data like log messages and notifications easy to explore and analyse.
* `InfluxDB <http://influxdb.com/>`_, an open-source and distributed time-series database to store and search metrics.

By combining Elasticsearch with `Kibana <http://www.elasticsearch.org/overview/kibana/>`_,
the LMA Toolchain provides an effective way to search and correlate all service-affecting events
that occurred in the system for root cause analysis.

Likewise, by combining InfluxDB with `Grafana <http://grafana.org/>`_, the LMA Toolchain
brings you insightful metrics analytics to visualise how OpenStack behaves over time.
This includes metrics for the OpenStack services status and a variety of resource usage
and performance indicators. The ability to visualise time-series over a period of time that
can vary from 5 minutes to the last 30 days helps anticipating failure conditions and plan
capacity ahead of time to cope with a changing demand.

Furthermore, the LMA Toolchain has been designed with the dual objective to be both insightful and adaptive.

It is, for example, quite possible (without any code change) to integrate the Collector
with an external monitoring application like Nagios. This could simply be done through enabling
the Nagios output plugin of Heka for a subset of messages matching the
`message matcher <https://hekad.readthedocs.io/en/latest/message_matcher.html#message-matcher>`_
syntax of the output plugin. You should probably not modify the configuration of the LMA
Collector manually but apply any configuration change to the Puppet manifests that are shipped
with the LMA Collector plugin for Fuel. Many other integration combinations are possible thanks
to the extreme flexibility of Heka.

We recommend you to read the Heka `documentation <https://hekad.readthedocs.io/en/latest/index.html>`_
to become more familiar with that technology.

The rest of this document is organised in several chapters that will take you through a
description of the internal message structure for the categories of operational data
that are handled by the LMA Toolchain.
