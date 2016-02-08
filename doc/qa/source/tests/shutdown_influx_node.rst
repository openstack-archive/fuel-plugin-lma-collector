+---------------+----------------------------------------------------------------------+
| Test Case ID  | shutdown_influxdb_node                                               |
+---------------+----------------------------------------------------------------------+
| Description   | Verify that failover for InfluxDB cluster works.                     |
+---------------+----------------------------------------------------------------------+
| Prerequisites | Environment deployed with the 4 plugins (See :ref:`deploy_ha_mode`). |
+---------------+----------------------------------------------------------------------+

Steps
:::::

#. Connect to any influxdb_grafana node and run command 'crm status'.

#. Shutdown node were vip_influxdb was started.

#. Check that vip_influxdb was started on another influxdb_grafana node.

#. Check the plugin services using CLI.

#. Check that Grafana UI works correctly.

#. Check that no data lost after shutdown.

#. Run OSTF.


Expected Result
:::::::::::::::

The OSTF tests pass successfully.

All the plugin services are running and work as expected after each
modification of the environment.

vip_influxdb was started on another node after shutdown.
