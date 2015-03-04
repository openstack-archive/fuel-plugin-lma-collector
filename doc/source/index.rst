===========================================
Welcome to the LMA Collector Documentation!
===========================================

The Logging, Monitoring and Alerting (LMA) Collector, that we will refer hereafter as the LMA Collector or just the Collector,
is a **Fuel plugin** which gathers raw operational data from a variety of sources including log messages,
`CollectD <https://collectd.org/>`_, and the `OpenStack notifications <https://wiki.openstack.org/wiki/SystemUsageData>`_
to be sent to external systems that will take action on them.

Overview
=========

The goal of the LMA Collector is to capture all **raw operational data** that we think are relevant to **increase the operational visibility**
of your OpenStack cloud.

To achieve that goal, the raw operational data are parsed and sanitised to be turned into an **internal
`Heka <https://github.com/mozilla-services/heka>`_ message representation** that can
be further processed and routed to external systems that will take action on them.
Examples of external systems handled by the LMA Collector out-of-the-box include:

* `ElasticSearch <http://www.elasticsearch.org/>`_, a powerful open source search server based on Lucene and analytics
  engine that makes data like log messages and notifications easy to explore and correlate
* `InfluxDB <http://influxdb.com/>`_, an open-source and distributed time-series database to store system metrics.

By combining the Collector with ElasticSearch and `Kibana <http://www.elasticsearch.org/overview/kibana/>`_,
the LMA Toolchain provides an end-to-end solution that delivers real-time insights about all events in your OpenStack cloud.
This can very useful to detect errors and search for their root cause.

Likewise, combining the Collector with InfluxDB and its `Grafana’s <http://grafana.org/>`_ metrics analytics front-end,
allows you to identify service failures, troubleshot performance bottlenecks and plan the capacity needed to meet changing demands
for your OpenStack cloud.

The LMA Collector can be viewed as a **pluggable processing and routing pipeline** for operational data.
Its core constituants are :

* CollectD that is provided with a large collection of service checks and system stats plugins
* Heka is an open-source stream processing software written in Go developed by Mozilla.
  Heka is the cornerstone component of the LMA Collector. 
* A collection of Heka plugins written in LUA to turn the raw operational data into structured
  messages that can be further analyzed and routed by other Heka plugins. 

Lastly, the LMA Collector is designed to be both insightful and adaptable to your own specific environment.

For example, thanks to Heka's extensibility, it is quite easy to plug an external monitoring system like Nagios into the LMA Collector.
This is simply done through enabling the Nagios output plugin and define the appropriate
`message matcher <https://hekad.readthedocs.org/en/v0.9.0/message_matcher.html#message-matcher>`_ criteria
for the category of messages you want to send out to Nagios. You should obviously not do that through hacking the
configuration of the nodes running production but through modifying and reapplying the Puppet manifests that shipped with the Fuel plugin. 
We also encourage you to read the Heka `documentation <https://hekad.readthedocs.org/en/v0.9.0/index.html>`_ to get familiar with the technology.

The rest of this documents is organised in several chapters that will take you through a description of the internal message
format used for each category of operational data that are handled by the Collector.


Table of Contents
=================

.. toctree::
   :maxdepth: 2

   collector
   logs
   notifications
   metrics
   outputs

Indices and Tables
==================

* :ref:`genindex`
* :ref:`modindex`
* :ref:`search`
