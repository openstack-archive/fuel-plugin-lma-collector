+---------------+----------------------------------------------------------------------+
| Test Case ID  | modify_influxdb_plugin_remove_add_node                               |
+---------------+----------------------------------------------------------------------+
| Description   | Verify that InfluxDB cluster can scale up and down.             |
+---------------+----------------------------------------------------------------------+
| Prerequisites | Environment deployed with the 4 plugins (See :ref:`deploy_ha_mode`). |
+---------------+----------------------------------------------------------------------+

Steps
:::::

#. Remove 1 node with the influxdb_grafana role.

#. Re-deploy the cluster.

#. Run command 'curl -u root:<rootpassword> -G 'http://{vip_influxdb}:8086/query' --data-urlencode 'q=SHOW SERVERS''

#. Check that output contains information about only two InfluxDB nodes.

#. Check the plugin services using CLI.

#. Check that Grafana UI works correctly.

#. Run OSTF.

#. Add 1 new  node with the influxdb_grafana role.

#. Re-deploy cluster.

#. Run command 'curl -u root:<rootpassword> -G 'http://{vip_influxdb}:8086/query' --data-urlencode 'q=SHOW SERVERS''

#. Check that output contains information about three InfluxDB nodes.

#. Check the plugin services using CLI.

#. Check that Grafana UI works correctly.

#. Run OSTF.


Expected Result
:::::::::::::::

The OSTF tests pass successfully.

All the plugin services are running and work as expected after each
modification of the environment.

The Nagios service has been reconfigured to take care of the node removal and
addition.
