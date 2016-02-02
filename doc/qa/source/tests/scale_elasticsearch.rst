+---------------+---------------------------------------------------------------------+
| Test Case ID  | modify_elasticsearch_plugin_remove_add_node                         |
+---------------+---------------------------------------------------------------------+
| Description   | Verify that elasticsearch cluster can scale up and down.            |
+---------------+---------------------------------------------------------------------+
| Prerequisites | Environment deployed with the 4 plugins (See :ref:`deploy_ha_mode`).|
+---------------+---------------------------------------------------------------------+

Steps
:::::

#. Remove 1 node with the elasticsearch_kibana role.

#. Re-deploy the cluster.

#. Check the plugin services using CLI.

#. Check that the Kibana UI works correctly.

#. Run OSTF.

#. Add 1 new node with the elasticsearch_kibana role.

#. Re-deploy cluster.

#. Check the plugin services using CLI.

#. Check that the Kibana UI works correctly.

#. Run OSTF.


Expected Result
:::::::::::::::

The OSTF tests pass successfully.

Grafana dashboard and Nagios UI reports a short downtime for Elasticsearch cluster.

All the plugin services are running and work as expected after each
modification of the environment.

The Nagios service has been reconfigured to take care of the node removal and
addition.
