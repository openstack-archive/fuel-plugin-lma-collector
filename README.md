Logging, Monitoring and Alerting (LMA) Collector Plugin for Fuel
================================================================


Overview
--------

The Logging, Monitoring & Alerting (LMA) collector is a service running on each
OpenStack node that collects logs, OpenStack notifications and metrics.

* Logs and notifications are sent to an Elasticsearch server for diagnostic,
troubleshooting and alerting purposes.
* Metrics are sent to an InfluxDB server for usage and performance analysis as
well as alerting purposes.


Requirements
------------


| Requirement                    | Version/Comment                                               |
| ------------------------------ | ------------------------------------------------------------- |
| Mirantis OpenStack compatility | 6.1 or higher                                                 |
| A running Elasticsearch server | 1.4 or higher, the RESTful API must be enabled over port 9200 |
| A running InfluxDB server      | 0.8.8,  the RESTful API must be enabled over port 8086        |


Limitations
-----------

The plugin is only compatible with OpenStack environments deployed with Neutron
for networking.

Installation Guide
==================


Prior to installing the LMA Collector Plugin, you may want to install its
dependencies:

* Elasticsearch and Kibana
* InfluxDB and Grafana

To install them automatically using Fuel, you can refer to the
[Elasticsearch-Kibana Fuel Plugin
](https://github.com/stackforge/fuel-plugin-elasticsearch-kibana).
and [InfluxDB-Grafana Fuel Plugin
](https://github.com/stackforge/fuel-plugin-influxdb-grafana)

You can install Elasticsearch/Kibana and InfluxDB/Grafana outside of Fuel as
long as your installation meets the LMA Collector plugin's requirements defined
above.


**LMA collector plugin** installation
-------------------------------------

To install the LMA Collector plugin, follow these steps:

1. Download the plugin from the [Fuel Plugins
   Catalog](https://software.mirantis.com/download-mirantis-openstack-fuel-plug-ins/).
2. Copy the plugin file to the Fuel Master node.

    ```
    scp lma_collector-0.7-0.7.0-0.noarch.rpm root@<Fuel Master node IP address>:
    ```

3. Install the plugin using the `fuel` command line:

    ```
    fuel plugins --install lma_collector-0.7-0.7.0-0.noarch.rpm
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
3. Scroll down the page, select the LMA collector plugin checkbox and
fill-in
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
    # On CentOS
    /etc/init.d/lma_collector status
    # On Ubuntu
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

**0.7.0**

* Initial release of the plugin. This is a beta version.

Development
===========

Contributions
-------------

If you would like to contribute to the development of this Fuel plugin you must
follow the workflow documented at:

   [OpenStack development workflow](http://docs.openstack.org/infra/manual/developers.html#development-workflow)

Bugs should be filled on Launchpad (not GitHub) with the tag `lma`:

   [Launchpad fuel-plugins project](https://bugs.launchpad.net/fuel-plugins)

Patch reviews take place here:

   [LMA reviews](https://review.openstack.org/#/q/status:open+project:stackforge/fuel-plugin-lma-collector,n,z)

The *OpenStack Development Mailing List* is the prefered way to communicate:

   Send an email to `openstack-dev@lists.openstack.org` with the subject prefixed by `[fuel][plugins][lma]`

Contributors
------------

* Guillaume Thouvenin <gthouvenin@mirantis.com>
* Simon Pasquier <spasquier@mirantis.com>
* Swann Croiset <scroiset@mirantis.com>

