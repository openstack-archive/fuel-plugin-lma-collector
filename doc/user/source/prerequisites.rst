.. _plugin_prerequisites:

Prerequisites
-------------

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