Test Strategy
=============

The test plan implements system, functional and non-functional tests. These
tests will be automated but tests of the user interfaces will have to be done
manually.

Acceptance Criteria
-------------------

#. The plugins can be installed and enabled on the Fuel master node.

#. The LMA Collector service is deployed on all the nodes of the environment
   including nodes with the 'base-os' role and custom roles (influxdb_grafana,
   elasticsearch_kibana, infrastructure_alerting).

#. The Elasticsearch server and the Kibana UI are deployed on one node with the elasticsearch_kibana role.

#. The InfluxDB server and the Grafana UI are deployed on one node with the influxdb_grafana role.

#. The Nagios server and dashboard are deployed on one node with the infrastructure_alerting role.

#. Kibana UI can be used to index and search both log messages and notifications.

#. The Grafana dashboards display detailed metrics for the main OpenStack services.

#. The Nagios UI displays status of all nodes and OpenStack services.

#. The plugins can be uninstalled when no environment uses them.


Test environment, infrastructure and tools
------------------------------------------

The 4 LMA plugins are installed on the Fuel master node.

For the controller nodes, it is recommended to deploy on hosts with at least 2
CPUs and 4G of RAM.


Product compatibility matrix
----------------------------

+------------------------------------+-----------------+
| Product                            | Version/Comment |
+====================================+=================+
| Mirantis OpenStack                 | 8.0, 9.0        |
+------------------------------------+-----------------+
| LMA collector plugin               | 0.10.0          |
+------------------------------------+-----------------+
| Elasticsearch-Kibana plugin        | 0.10.0          |
+------------------------------------+-----------------+
| InfluxDB-Grafana plugin            | 0.10.0          |
+------------------------------------+-----------------+
| LMA Infrastructure Alerting plugin | 0.10.0          |
+------------------------------------+-----------------+
