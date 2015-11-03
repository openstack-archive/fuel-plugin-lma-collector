
+---------------+--------------------------------------------------------------------------+
| Test Case ID  | query_keystone_notifications_in_kibana_ui                                |
+---------------+--------------------------------------------------------------------------+
| Description   | Verify that the Keystone notifications show up in the Kibana UI.         |
+---------------+--------------------------------------------------------------------------+
| Prerequisites | Environment deployed with the 4 plugins (see :ref:`deploy_lma_plugins`). |
+---------------+--------------------------------------------------------------------------+

Steps
:::::

#. Run OSTF platform test: 'Ceilometer test to check notifications from Keystone'.

#. Open the Kibana URL at :samp:`http://<{IP address of the 'lma' node}>/`

#. Open the Notifications dashboard using the 'Load' icon.

#. Enter 'keystone' in the Query box.


Expected Result
:::::::::::::::

All `event types for Keystone <https://docs.google.com/a/mirantis.com/spreadsheets/d/1ES_hWWLpn_eAur2N1FPNyqQAs5U36fQOcuCxRZjHESY/edit?usp=sharing>`_
are listed.
