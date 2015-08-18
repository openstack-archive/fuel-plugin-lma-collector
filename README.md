Logging, Monitoring and Alerting (LMA) Collector Plugin for Fuel
================================================================


Overview
--------

The Logging, Monitoring & Alerting (LMA) collector is a service running on each
OpenStack node that collects logs, OpenStack notifications and metrics. It is
also able to detect anomalous events and generate alerts to external monitoring
systems.

* Logs and notifications are sent to an Elasticsearch server for diagnostic,
troubleshooting and alerting purposes.
* Metrics are sent to an InfluxDB server for usage and performance analysis as
well as alerting purposes.
* Alerts are sent to a Nagios server.


Requirements
------------


| Requirement                    | Version/Comment                                               |
| ------------------------------ | ------------------------------------------------------------- |
| Mirantis OpenStack compatility | 6.1 or higher                                                 |
| A running Elasticsearch server | 1.4 or higher, the RESTful API must be enabled over port 9200 |
| A running InfluxDB server      | 0.9.2,  the RESTful API must be enabled over port 8086        |
| A running Nagios server        | 3.5 or higher, the command CGI must be enabled                |


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
Infrastructure Fuel
Plugin](https://github.com/stackforge/fuel-plugin-lma-infrastructure-alerting).

You can install Elasticsearch/Kibana, InfluxDB/Grafana and Nagios outside of
Fuel as long as your installation meets the LMA Collector plugin's requirements
defined above.


**LMA collector plugin** installation
-------------------------------------

To install the LMA Collector plugin, follow these steps:

1. Download the plugin from the [Fuel Plugins
   Catalog](https://software.mirantis.com/download-mirantis-openstack-fuel-plug-ins/).
2. Copy the plugin file to the Fuel Master node.

    ```
    scp lma_collector-0.8-0.8.0-0.noarch.rpm root@<Fuel Master node IP address>:
    ```

3. Install the plugin using the `fuel` command line:

    ```
    fuel plugins --install lma_collector-0.8-0.8.0-0.noarch.rpm
    ```

4. Verify that the plugin is installed correctly:

    ```
    fuel plugins --list
    ```

Please refer to the [Fuel Plugins
wiki](https://wiki.openstack.org/wiki/Fuel/Plugins) if you want to build the
plugin by yourself, version 2.0.0 (or higher) of the Fuel Plugin Builder is
required.

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

* Support for alerting with 2 modes:
  * Email notifications.
  * Integration with Nagios.
* Support of InfluxDB 0.9.2 and higher.
* Management of the LMA collector service by Pacemaker on the controller nodes
  for improved reliability.
* Monitoring of the LMA toolchain components.

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
* Simon Pasquier <spasquier@mirantis.com>
* Swann Croiset <scroiset@mirantis.com>
