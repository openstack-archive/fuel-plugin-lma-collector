.. _user_installation:

Installation
============

Prior to installing the LMA Collector Plugin, you may want to install its
dependencies:

* Elasticsearch and Kibana for log analytics
* InfluxDB and Grafana for metrics analytics
* Nagios for alerting

To install them automatically you can refer to the:

1. `Elasticsearch-Kibana Fuel Plugin Installation Guide <http://fuel-plugin-elasticsearch-kibana.readthedocs.org/en/latest/installation.html#installation-guide>`_.
2. `InfluxDB-Grafana Fuel Plugin Installation Guide <http://fuel-plugin-influxdb-grafana.readthedocs.org/en/latest/installation.html#installation-guide>`_.
3. `Infrastructure Alerting Fuel Plugin Installation Guide <http://fuel-plugin-lma-infrastructure-alerting.readthedocs.org/en/latest/installation.html#installation-guide>`_.

You can install Elasticsearch/Kibana, InfluxDB/Grafana and Nagios outside of the
Fuel Plugin framework as long as your installation meets the LMA Collector plugin's :ref:`requirements <plugin_requirements>`.


LMA Collector Fuel Plugin install using the RPM file of the Fuel Plugins Catalog
--------------------------------------------------------------------------------

To install the LMA Collector Fuel Plugin using the RPM file of the Fuel Plugins
Catalog, you need to follow these steps:

1. Download the RPM file from the `Fuel Plugins Catalog <https://software.mirantis.com/download-mirantis-openstack-fuel-plug-ins/>`_.

2. Copy the RPM file to the Fuel Master node::

    [root@home ~]# scp lma_collector-0.9-0.9.0-1.noarch.rpm \
    root@<Fuel Master node IP address>:

3. Install the plugin using the `Fuel CLI <http://docs.mirantis.com/openstack/fuel/fuel-7.0/user-guide.html#using-fuel-cli>`_::

    [root@fuel ~]# fuel plugins --install lma_collector-0.8-0.8.0-1.noarch.rpm

4. Verify that the plugin is installed correctly::

    [root@fuel ~]# fuel plugins --list
    id | name                 | version | package_version
    ---|----------------------|---------|----------------
    1  | lma_collector        | 0.8.0   | 2.0.0


LMA Collector Fuel Plugin install from source
---------------------------------------------

Alternatively, you may want to build the RPM file of the plugin from source
if, for example, you want to test the latest features, modify some built-in
configuration or implement your own customization.
But note that running a Fuel plugin that you have built yourself is at your own risk.

To install LMA Collector Plugin from source, you first need to prepare an
environement to build the RPM file.
The recommended approach is to build the RPM file directly onto the Fuel Master
node so that you won't have to copy that file later on.

**Prepare an environment for building the plugin on the Fuel Master Node**

1. Install the standard Linux development tools::

    [root@home ~] yum install createrepo rpm rpm-build dpkg-devel

2. Install the Fuel Plugin Builder. To do that, you should first get pip::

    [root@home ~] easy_install pip

3. Then install the Fuel Plugin Builder (the `fpb` command line) with `pip`::

    [root@home ~] pip install fuel-plugin-builder

**Note**: You may also need to build the Fuel Plugin Builder if the package version of the
plugin is higher than package version supported by the Fuel Plugin Builder you get from `pypi`.
In this case, please refer to the section "Preparing an environment for plugin development"
of the `Fuel Plugins wiki <https://wiki.openstack.org/wiki/Fuel/Plugins>`_
if you need further instructions about how to build the Fuel Plugin Builder.

4. Clone the plugin git repository::

    [root@home ~] git clone git@github.com:openstack/fuel-plugin-lma_collector.git

5. Check that the plugin is valid::

    [root@home ~] fpb --check ./fuel-plugin-lma_collector

6.  And finally, build the plugin::

    [root@home ~] fpb --build ./fuel-plugin-lma_collector

7. Now that you have created the RPM file, you can install the plugin using the `fuel plugins --install` command::

    [root@fuel ~] fuel plugins --install ./fuel-plugin-lma_collector/*.noarch.rpm
