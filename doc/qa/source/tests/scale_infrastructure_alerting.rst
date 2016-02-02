+---------------+---------------------------------------------------------------------+
| Test Case ID  | modify_lma_infrastructure_alerting_plugin_remove_add_node           |
+---------------+---------------------------------------------------------------------+
| Description   | Verify that infrastructure alerting cluster can scale up and down.  |
+---------------+---------------------------------------------------------------------+
| Prerequisites | Environment deployed with the 4 plugins (See :ref:`deploy_ha_mode`).|
+---------------+---------------------------------------------------------------------+

Steps
:::::

#. Remove 1 node with the infrastructure_alerting role. 

#. Re-deploy the cluster.

#. Check the plugin services using cli.

#. Check that Nagios UI works correctly.

#. Run OSTF.

#. Add 1 new  node with the infrastructure_alerting role.

#. Re-deploy cluster.

#. Check the plugin services using cli.

#. Check that Nagios UI works correctly.

#. Run OSTF.


Expected Result
:::::::::::::::

The OSTF tests pass successfully.

All the plugin services are running and work as expected after each
modification of the environment.

The Nagios service has been reconfigured to take care of the node removal and
addition.
