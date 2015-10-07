Logging, Monitoring and Alerting (LMA) Collector Plugin for Fuel
================================================================


Overview
--------
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

Requirements
------------


| Requirement                                              | Version/Comment                                                 |
| -------------------------------------------------------- | --------------------------------------------------------------- |
| Mirantis OpenStack compatility                           | 6.1 or higher                                                   |
| A running Elasticsearch server<br>(for log analytics)    | 1.4 or higher, the RESTful API must be enabled over port 9200   |
| A running InfluxDB server<br>(for metric analytics)      | 0.9.4 or higher, the RESTful API must be enabled over port 8086 |
| A running Nagios server<br>(for infrastructure alerting) | 3.5 or higher, the command CGI must be enabled                  |


Limitations
-----------

The plugin is only compatible with OpenStack environments deployed with Neutron
for networking.

Installation Guide
==================

Prior to installing the LMA Collector Plugin, you may want to install its
dependencies:

* Elasticsearch and Kibana for log analytics
* InfluxDB and Grafana for metrics analytics
* Nagios for alerting

To install them automatically using Fuel, you can refer to the
[Elasticsearch-Kibana Fuel Plugin
](https://github.com/stackforge/fuel-plugin-elasticsearch-kibana)
, [InfluxDB-Grafana Fuel Plugin
](https://github.com/stackforge/fuel-plugin-influxdb-grafana) and [LMA
Infrastructure Alerting Fuel Plugin
](https://github.com/stackforge/fuel-plugin-lma-infrastructure-alerting).

You can install Elasticsearch/Kibana, InfluxDB/Grafana and Nagios outside of
Fuel as long as your installation meets the LMA Collector Plugin's requirements
defined above.


LMA collector plugin install from the RPM file
----------------------------------------------

To install the LMA Collector Plugin from the RPM file of the plugin, follow these steps:

1. Download the RPM file from the [Fuel Plugins
   Catalog](https://software.mirantis.com/download-mirantis-openstack-fuel-plug-ins/).

2. Copy the RPM file to the Fuel Master node.

    ```
    # scp lma_collector-0.8-0.8.0-0.noarch.rpm root@<Fuel Master node IP address>:
    ```

3. Install the RPM file using the `fuel` command line:

    ```
    # fuel plugins --install lma_collector-0.8-0.8.0-0.noarch.rpm
    ```

4. Verify that the plugin is installed correctly:

    ```
    # fuel plugins --list
    ```

LMA collector plugin install from source
----------------------------------------

To install the LMA Collector Plugin from source, you first need to prepare an
environement to build the RPM file of the plugin.
The recommended approach is to build the RPM file directly onto the Fuel Master
node so that you won't have to copy that file later.

**Prepare an environment for building the plugin on the Fuel Master Node**

1. Install the standard Linux development tools:

    ```
    # yum install createrepo rpm rpm-build dpkg-devel
    ```

2. Install the Fuel Plugin Builder. To do that, you should first get pip:

    ```
    # easy_install pip
    ```

3. Then install the Fuel Plugin Builder (the `fpb` command line) with `pip`:

    ```
    # pip install fuel-plugin-builder
    ```

*Note: You may also have to build the Fuel Plugin Builder if the package version of the
plugin is higher than package version supported by the Fuel Plugin Builder you get from `pypi`.
In this case, please refer to the section "Preparing an environment for plugin development"
of the [Fuel Plugins wiki](https://wiki.openstack.org/wiki/Fuel/Plugins) if you
need further instructions about how to build the Fuel Plugin Builder.*

4. Clone the LMA Collector Plugin git repository:

    ```
    # git clone git@github.com:stackforge/fuel-plugin-lma-collector.git
    ```

5. Check that the plugin is valid:

    ```
    # fpb --check ./fuel-plugin-lma-collector
    ```

6.  And finally, build the plugin:

    ```
    # fpb --build ./fuel-plugin-lma-collector
    ```

6. Now you have created an RPM file that you can install using the steps described above:

    ```
    # ls -l fuel-plugin-lma-collector/lma_collector-0.8-0.8.0-1.noarch.rpm
    -rw-r--r-- 1 root root 27841564 16 sept. 16:18 fuel-plugin-lma-collector/lma_collector-0.8-0.8.0-1.noarch.rpm
    ```

User Guide
==========

**LMA collector plugin** configuration
--------------------------------------

1. Create a new environment with the Fuel UI wizard.
2. Click on the Settings tab of the Fuel web UI.
3. Scroll down the page, select the LMA collector plugin checkbox and fill-in
   the required fields.

Exploring the data
------------------

Refer to the [Elasticsearch/Kibana
plugin](https://github.com/stackforge/fuel-plugin-elasticsearch-kibana) for
exploring and visualizing the collected logs and notifications and refer to the
[InfluxDB-Grafana Fuel Plugin
](https://github.com/stackforge/fuel-plugin-influxdb-grafana) for monitoring
your cloud.

Troubleshooting
---------------

If you see no data in the Elasticsearch and/or InfluxDB  servers, check the
following:

1. The LMA collector service is running

    ```
    # On controller node
    crm resource status lma_collector
    # On CentOS (other than a controller)
    /etc/init.d/lma_collector status
    # On Ubuntu (other than a controller)
    status lma_collector
    ```

2. Look for errors in the LMA collector log file (located at
   `/var/log/lma_collector.log`) on the different nodes.
3. Nodes are able to connect to the Elasticsearch server on port 9200.
4. Nodes are able to connect to the InfluxDB server on port 8086.


Known issues
------------

None

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

Development
===========

The *OpenStack Development Mailing List* is the preferred way to communicate,
emails should be sent to `openstack-dev@lists.openstack.org` with the subject
prefixed by `[fuel][plugins][lma]`.

Running tests
-------------

You need to have `tox` and `bundler` installed for running the tests.

Quickstart for Ubuntu Trusty:

    ```
    apt-get install tox ruby
    gem install bundler
    tox
    ```

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
https://review.openstack.org/#/q/status:open+project:stackforge/fuel-plugin-lma-collector,n,z)
system.

Contributors
------------

* Guillaume Thouvenin <gthouvenin@mirantis.com>
* Patrick Petit <ppetit@mirantis.com>
* Simon Pasquier <spasquier@mirantis.com>
* Swann Croiset <scroiset@mirantis.com>
