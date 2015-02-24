Logging, Monitoring and Alerting collector Plugin for Fuel
==========================================================


Overview
--------

The Logging, Monitoring & Alerting (LMA) collector is a service running on each
OpenStack node that collects logs and notifications. This data is sent to an
ElasticSearch server for diagnostic, troubleshooting and alerting purposes.


Requirements
------------


| Requirement                    | Version/Comment                                               |
| ------------------------------ | ------------------------------------------------------------- |
| Mirantis OpenStack compatility | 6.1 or higher                                                 |
| A running ElasticSearch server | 1.4 or higher, the RESTful API must be enabled over port 9200 |


Limitations
-----------

The plugin is only compatible with environments using Neutron.

Installation Guide
==================


ElasticSearch configuration
---------------------------

To install and configure ElasticSearch, you can refer to the
[ElasticSearch/Kibana
plugin](https://github.com/stackforge/fuel-plugin-elasticsearch-kibana) for
Fuel.

You can also install the ElasticSearch server outside of Fuel as long as it
meets the plugin's requirements.

**LMA collector plugin** installation
-------------------------------------

To install the LMA collector plugin, follow these steps:

1. Download the plugin from the [Fuel Plugins
   Catalog](https://software.mirantis.com/download-mirantis-openstack-fuel-plug-ins/).
2. Copy the plugin file to the Fuel Master node.
```
scp lma_collector-1.0.0.fp root@<IP address>:
```
3. Install the plugin using the `fuel` command line:
```
fuel plugins --install lma_collector-1.0.0.fp
```
4. Verify that the plugin is installed correctly:
```
fuel plugins --list
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

Refer to the [ElasticSearch/Kibana
plugin](https://github.com/stackforge/fuel-plugin-elasticsearch-kibana) for exploring and visualizing the collected data.

Troubleshooting
---------------

If you see no data in the ElasticSearch server, check the following:

1. The LMA collector service is running
```
# On CentOS
/etc/init.d/heka-collector status
# On Ubuntu
status heka-collector
```
2. Look for errors in the LMA collector log file (located at `/var/log/heka-collector.log`) on the different nodes.
3. Nodes are able to connect to the ElasticSearch server on port 9200.


Known issues
------------

None

Release Notes
-------------

**6.1.0**

* Initial release of the plugin.


Contributors
------------

* Guillaume Thouvenin <gthouvenin@mirantis.com>
* Simon Pasquier <spasquier@mirantis.com>
* Swann Croiset <scroiset@mirantis.com>
