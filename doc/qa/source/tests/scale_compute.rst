
+---------------+--------------------------------------------------------------------------+
| Test Case ID  | modify_env_with_plugin_remove_add_compute                                |
+---------------+--------------------------------------------------------------------------+
| Description   | Verify that the number of computes can scale up and down.                |
+---------------+--------------------------------------------------------------------------+
| Prerequisites | Environment deployed with the 4 plugins (See :ref:`deploy_lma_plugins`). |
+---------------+--------------------------------------------------------------------------+

Steps
:::::

#. Remove 1 node with the compute role.

#. Re-deploy the cluster.

#. Check the plugin services using the CLI

#. Check in the Nagios UI that the removed node is no longer monitored.

#. Run the health checks (OSTF).

#. Add 1 new  node with the compute role.

#. Re-deploy the cluster.

#. Check the plugin services using the CLI.

#. Check in the Nagios UI that the new node is monitored.

#. Run the health checks (OSTF).


Expected Result
:::::::::::::::

The OSTF tests pass successfully.

All the plugin services are running and work as expected after each
modification of the environment.

The Nagios service has been reconfigured to take care of the node removal and
addition.
