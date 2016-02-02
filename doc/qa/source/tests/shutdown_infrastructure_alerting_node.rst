+---------------+----------------------------------------------------------------------+
| Test Case ID  | shutdown_infrastructure_alerting_node                                |
+---------------+----------------------------------------------------------------------+
| Description   | Verify that failover for infrastructure alerting cluster works.      |
+---------------+----------------------------------------------------------------------+
| Prerequisites | Environment deployed with the 4 plugins (See :ref:`deploy_ha_mode`). |
+---------------+----------------------------------------------------------------------+

Steps
:::::

#. Connect to any infrastructure_alerting node and run command 'crm status'.

#. Shutdown node were vip_infrastructure_alerting_mgmt_vip was started.

#. Check that vip_infrastructure_alerting was started on another influxdb node.

#. Check the plugin services using cli.

#. Check that Nagios UI works correctly.

#. Check that no data lost after shutdown.

#. Run OSTF.


Expected Result
:::::::::::::::

The OSTF tests pass successfully.

All the plugin services are running and work as expected after each
modification of the environment.

vip_infrastructure_alerting_mgmt_vip was started on another node after shutdown.
