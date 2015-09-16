.. _user_installation:

Installation
============

Prior to installing the LMA Collector Plugin, you may want to install its
dependencies:

* Elasticsearch and Kibana for log analytics
* InfluxDB and Grafana for metrics analytics
* Nagios for alerting

To install them automatically using Fuel, you can refer to the
Elasticsearch-Kibana Fuel Plugin, InfluxDB-Grafana Fuel Plugin, and LMA
Infrastructure Alerting Fuel Plugin documentation in the `Fuel Plugins Catalog <https://software.mirantis.com/download-mirantis-openstack-fuel-plug-ins/>`_.

You can install Elasticsearch/Kibana, InfluxDB/Grafana and Nagios outside of
Fuel as long as your installation meets the LMA Collector plugin's :ref:`requirements <plugin_requirements>`.


Install the plugin on the Fuel master node
------------------------------------------

To install the LMA Collector plugin, follow these steps:

1. Download the plugin from the `Fuel Plugins Catalog <https://software.mirantis.com/download-mirantis-openstack-fuel-plug-ins/>`_.

2. Copy the plugin file to the Fuel Master node::

    [root@home ~]# scp lma_collector-0.8-0.8.0-1.noarch.rpm root@<Fuel Master node IP address>:


3. Install the plugin using the `Fuel CLI <http://docs.mirantis.com/openstack/fuel/fuel-7.0/user-guide.html#using-fuel-cli>`_::

    [root@fuel ~]# fuel plugins --install lma_collector-0.8-0.8.0-1.noarch.rpm


4. Verify that the plugin is installed correctly::

    [root@fuel ~]# fuel plugins --list
    id | name                 | version | package_version
    ---|----------------------|---------|----------------
    1  | lma_collector        | 0.8.0   | 2.0.0


Alternatively, you may want to build the rpm file of the plugin yourself if,
for example, you want to modify some configuration elements. But note that this
is at your own risk. Detailed instructions to build the LMA Collector plugin
are provided in the README.md file of the `project <https://github.com/stackforge/fuel-plugin-lma-collector>`_.
