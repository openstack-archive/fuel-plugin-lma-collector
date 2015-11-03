
+---------------+---------------------------------------------------------------------------------------+
| Test Case ID  | uninstall_plugin_with_deployed_env                                                    |
+---------------+---------------------------------------------------------------------------------------+
| Description   | Verify that the plugins can be uninstalled after the deployed environment is removed. |
+---------------+---------------------------------------------------------------------------------------+
| Prerequisites | Environment deployed with the 4 plugins (see :ref:`deploy_lma_plugins`).              |
+---------------+---------------------------------------------------------------------------------------+

Steps
:::::

#. Try to remove the plugins using the Fuel CLI and ensure that the command
   fails with "Can't delete plugin which is enabled for some environment".

#. Remove the environment.

#. Remove the plugins.

Expected Result
:::::::::::::::

An alert is raised when we try to delete plugins which are attached to an active environment.

After the environment is removed, the plugins are removed successfully too.
