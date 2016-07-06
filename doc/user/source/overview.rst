.. _user_overview:

Overview
========

The **StackLight Collector Plugin** is used to install and configure
several software components that are used to collect and process all the
data that we think is relevant to provide deep operational insights about
your OpenStack environment. These finely integrated components are
collectively referred to as the **StackLight Collector** (or just **the Collector**).

.. note:: The Collector has evolved over time and so the term
   'collector' is a little bit of a misnomer since it is
   more of a **smart monitoring agent** than a mere data 'collector'.

The Collecor is a key component of the so-called
`Logging, Monitoring and Alerting toolchain of Mirantis OpenStack
<https://launchpad.net/lma-toolchain>`_ (a.k.a StackLight).

.. image:: ../../images/toolchain_map.png
   :align: center

The Collector is installed on every node of your OpenStack
environment. Each Collector is individually responsible for supporting
all the monitoring functions of your OpenStack environment for both
the operating system and the services running on the node.
Note also that the Collector running on the *primary controller*
(the controller which owns the management VIP) is called the
**Aggregator** since it performs additional aggregation and correlation
functions. The Aggregator is the central point of convergence for
all the faults and anomalies detected at the node level. The
fundamental role of the Aggregator is to issue an opinion about the
health status of your OpenStack environment at the cluster
level. As such, the Collector may be viewed as a monitoring
agent for cloud infrastructure clusters.

The main building blocks of the Collector are:

* **collectd** which comes bundled with a collection of monitoring plugins.
  Some of them are standard collectd plugins while others are purpose-built
  plugins written in python to perform various OpenStack services checks.
* **Heka**, `a golang data processing swiss army knife by Mozilla
  <https://github.com/mozilla-services/heka>`_.
  Heka supports a number of standard input and output plugins
  that allows to ingest data from a variety of sources
  including collectd, log files and RabbitMQ,
  as well as to persist the operational data to external backend servers like
  Elasticsearch, InfluxDB and Nagios for search and further processing.
* **A collection of Heka plugins** written in Lua which does
  the actual data processing such as running metrics transformations
  and running alarms.

.. note:: An important function of the Collector is to normalize
   the operational data into an internal `Heka message structure
   <https://hekad.readthedocs.io/en/stable/message/index.html>`_
   representation that can be ingested into the Heka's stream processing
   pipeline. The stream processing pipeline uses matching policies to
   route the Heka messages to the `Lua <http://www.lua.org/>`_ plugins that
   will perform the actual data computation functions.

There are three types of Lua plugins that were developed for the Collector:

* The **decoder plugins** to sanitize and normalize the ingested data.
* The **filter plugins** to process the data.
* The **encoder plugins** to serialize the data that is
  sent to the backend servers.

There are five types of data sent by the Collector (and the Aggregator)
to the backend servers:

* The logs and the notifications, which are referred to as events,
  sent to Elasticsearch for indexing.
* The metric's time-series sent to InfluxDB.
* The annotation sent to InfluxDB.
* The OpenStack environment clusters health status
  sent as *passive checks* to Nagios

.. note:: The annotations are like notification messages
   which are exposed in Grafana. They contain information about the
   anomalies and faults that have been detected by the Collector.
   They are also used to construct the *passive checks* sent to Nagios.
   They may additionally contain 'hints' about what the Collector think
   could be the root cause of a problem.

.. _plugin_requirements:

Requirements
------------

+-------------------------------------------------------+-------------------------------------------------------------------+
| Requirement                                           | Version/Comment                                                   |
+=======================================================+===================================================================+
| Mirantis OpenStack                                    | 8.0 or 9.0                                                        |
+-------------------------------------------------------+-------------------------------------------------------------------+
| A running Elasticsearch server (for log analytics)    | 1.7.4 or higher, the RESTful API must be enabled over port 9200   |
+-------------------------------------------------------+-------------------------------------------------------------------+
| A running InfluxDB server (for metric analytics)      | 0.10.0 or higher, the RESTful API must be enabled over port 8086  |
+-------------------------------------------------------+-------------------------------------------------------------------+
| A running Nagios server (for infrastructure alerting) | 3.5 or higher, the command CGI must be enabled                    |
+-------------------------------------------------------+-------------------------------------------------------------------+

Limitations
-----------

* The plugin is not compatible with an OpenStack environment deployed with nova-network.

* The Elasticsearch output plugin of the Collector is configured to use the **drop** policy
  which implies that the Collector will start dropping the logs and the OpenStack
  notifications when the output plugin has reached a buffering limit that is currently
  set to 1GB by default. This situation can typically happen when the Elasticsearch server
  has been inaccessible for a long period of time.
  This limitation may be addressed in a future release of the StackLight Collector Plugin.

* When you re-execute tasks on deployed nodes using the Fuel CLI, the *hekad* and
  *collectd* services will be restarted on these nodes during the post-deployment
  phase. See `bug #1570850
  <https://bugs.launchpad.net/lma-toolchain/+bug/1570850>`_ for details.
