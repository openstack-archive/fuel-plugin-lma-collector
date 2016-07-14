.. _plugin_prerequisites:

Prerequisites
-------------

Prior to installing the StackLight Collector plugin for Fuel, you may want to
install the back-end services the *collector* uses to store the data. These
back-end services include the following:

* Elasticsearch
* InfluxDB
* Nagios

There are two installation options:

#. Install the back-end services automatically within a Fuel environment using
   the following Fuel plugins:

   * `StackLight Elasticsearch-Kibana Fuel Plugin Installation Guide <http://fuel-plugin-elasticsearch-kibana.readthedocs.io/en/latest/installation.html#installation-guide>`_
   * `StackLight InfluxDB-Grafana Fuel Plugin Installation Guide <http://fuel-plugin-influxdb-grafana.readthedocs.io/en/latest/installation.html#installation-guide>`_
   * `StackLight Infrastructure Alerting Fuel Plugin Installation Guide <http://fuel-plugin-lma-infrastructure-alerting.readthedocs.io/en/latest/installation.html#installation-guide>`_

#. Install the back-end services manually outside of a Fuel environment.
   In this case, the installation must comply with the
   :ref:`requirements <plugin_requirements>` of the StackLight Collector
   plugin.