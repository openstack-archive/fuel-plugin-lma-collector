
+---------------+--------------------------------------------------------------------------+
| Test Case ID  | query_glance_notifications_in_kibana_ui                                  |
+---------------+--------------------------------------------------------------------------+
| Description   | Verify that the Glance notifications show up in the Kibana UI.           |
+---------------+--------------------------------------------------------------------------+
| Prerequisites | Environment deployed with the 4 plugins (see :ref:`deploy_lma_plugins`). |
+---------------+--------------------------------------------------------------------------+

Steps
:::::

#. Run the OSTF platform test "Check create, update and delete image actions using Glance v2".

#. Open the Kibana URL at :samp:`http://<{IP address of the 'lma' node}>/`

#. Open the Notifications dashboard using the 'Load' icon.

#. Enter 'glance' in the Query box.


Expected Result
:::::::::::::::

All `event types for Glance <https://docs.google.com/a/mirantis.com/spreadsheets/d/1ES_hWWLpn_eAur2N1FPNyqQAs5U36fQOcuCxRZjHESY/edit?usp=sharing>`_
are listed.
