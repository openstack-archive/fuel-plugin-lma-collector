.. _user_installation:

Installation
============

Prior to installing the StackLight Collector Plugin,
you may want to install the backend services the *collector* uses
to store the data. These backend services include:

* Elasticsearch
* InfluxDB
* Nagios

There are two installation options:

1. Install the backend services automatically within a Fuel environment using the Fuel Plugins listed below.

  * `StackLight Elasticsearch-Kibana Fuel Plugin Installation Guide <http://fuel-plugin-elasticsearch-kibana.readthedocs.io/en/latest/installation.html#installation-guide>`_.
  * `StackLight InfluxDB-Grafana Fuel Plugin Installation Guide <http://fuel-plugin-influxdb-grafana.readthedocs.io/en/latest/installation.html#installation-guide>`_.
  * `StackLight Infrastructure Alerting Fuel Plugin Installation Guide <http://fuel-plugin-lma-infrastructure-alerting.readthedocs.io/en/latest/installation.html#installation-guide>`_.

2. Install the backend services on your own outside of a Fuel environment.
   Note that in this case, the installation must comply with the StackLight Collector
   Plugin's :ref:`requirements <plugin_requirements>`.


StackLight Collector Fuel Plugin installation using the RPM file of the Fuel Plugins Catalog
--------------------------------------------------------------------------------------------

To install the StackLight Collector Fuel Plugin using the RPM file of the Fuel Plugins
Catalog, follow these steps:

1. Select, using the *MONITORING* category and Mirantis OpenStack version you are using, the RPM file
   you want to download from the
   `Fuel Plugins Catalog <https://www.mirantis.com/validated-solution-integrations/fuel-plugins/>`_

2. Copy the RPM file to the Fuel Master node::

    [root@home ~]# scp lma_collector-0.10-0.10.0-1.noarch.rpm \
    root@<Fuel Master node IP address>:

3. Install the plugin using the
   `Fuel Plugins CLI <http://docs.openstack.org/developer/fuel-docs/userdocs/fuel-user-guide/cli/cli_plugins.html>`_::

    [root@fuel ~]# fuel plugins --install lma_collector-0.10-0.10.0-1.noarch.rpm

4. Verify that the plugin is installed correctly::

    [root@fuel ~]# fuel plugins --list
    id | name                 | version  | package_version
    ---|----------------------|----------|----------------
    1  | lma_collector        | 0.10.0   | 4.0.0


StackLight Collector Fuel Plugin installation from source
---------------------------------------------------------

Alternatively, you may want to build the RPM file of the plugin from source
if, for example, you want to test the latest features of the master branch
or customize the plugin.

.. note:: Be aware that running a Fuel plugin that you built yourself
   is at your own risk and will not be supported.

To install the StackLight Collector Plugin from source, you first need to prepare an
environement to build the RPM file.
The recommended approach is to build the RPM file directly onto the Fuel Master
node so that you won't have to copy that file later on.

**Prepare an environment to build the plugin on the Fuel Master Node**

1. Install the standard Linux development tools::

    [root@home ~] yum install createrepo rpm rpm-build dpkg-devel

2. Install the Fuel Plugin Builder. To do that, you should first get pip::

    [root@home ~] easy_install pip

3. Then install the Fuel Plugin Builder (the `fpb` command line) with `pip`::

    [root@home ~] pip install fuel-plugin-builder

.. note:: You may also need to build the Fuel Plugin Builder if the package version of the
   plugin is higher than the package version supported by the Fuel Plugin Builder you get from `pypi`.
   In this case, please refer to the section "Preparing an environment for plugin development"
   of the `Fuel Plugins wiki <https://wiki.openstack.org/wiki/Fuel/Plugins>`_
   if you need further instructions about how to build the Fuel Plugin Builder.

4. Clone the plugin git repository::

    [root@home ~] git clone https://github.com/openstack/fuel-plugin-lma-collector.git

5. Check that the plugin is valid::

    [root@home ~] fpb --check ./fuel-plugin-lma-collector

6.  And finally, build the plugin::

    [root@home ~] fpb --build ./fuel-plugin-lma-collector

7. Now that you have created the RPM file, you can install the plugin using the `fuel plugins --install` command::

    [root@fuel ~] fuel plugins --install ./fuel-plugin-lma-collector/*.noarch.rpm
