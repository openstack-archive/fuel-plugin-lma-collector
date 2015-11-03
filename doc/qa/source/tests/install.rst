
+---------------+-------------------------------------------+
| Test Case ID  | install_lma_plugins                       |
+---------------+-------------------------------------------+
| Description   | Verify that the plugins can be installed. |
+---------------+-------------------------------------------+
| Prerequisites | N/A                                       |
+---------------+-------------------------------------------+

Steps
:::::

#. Copy the 4 plugins to the Fuel master node using scp.

#. Connect to the Fuel master node using ssh.

#. Install the plugins using the fuel CLI.

#. Connect to the Fuel web UI.

#. Create a new environment using the Fuel UI Wizard.

#. Click on the Plugins tab.


Expected Result
:::::::::::::::

The 4 plugins are present in the Fuel UI.
