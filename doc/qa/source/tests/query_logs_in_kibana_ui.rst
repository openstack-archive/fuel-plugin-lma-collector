
+---------------+--------------------------------------------------------------------------+
| Test Case ID  | query_logs_in_kibana_ui                                                  |
+---------------+--------------------------------------------------------------------------+
| Description   | Verify that the logs show up in the Kibana UI.                           |
+---------------+--------------------------------------------------------------------------+
| Prerequisites | Environment deployed with the 4 plugins (see :ref:`deploy_lma_plugins`). |
+---------------+--------------------------------------------------------------------------+

Steps
:::::

#. Open the Kibana URL at :samp:`http://<{IP address of the 'lma' node}>/`

#. Enter 'programname:nova*' in the Query box.

#. Check that Nova logs are displayed.


Expected Result
:::::::::::::::

The Kibana UI displays entries for all the controller and compute nodes
deployed in the environment.
