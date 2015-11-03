
+---------------+--------------------------------------------------------------------------+
| Test Case ID  | query_cinder_notifications_in_kibana_ui                                  |
+---------------+--------------------------------------------------------------------------+
| Description   | Verify that the cinder notifications show up in the Kibana UI.           |
+---------------+--------------------------------------------------------------------------+
| Prerequisites | Environment deployed with the 4 plugins (see :ref:`deploy_lma_plugins`). |
+---------------+--------------------------------------------------------------------------+

Steps
:::::

#. Create and update a volume in the OpenStack environment (using the Horizon
   dashboard for example) and write down the volume id.

#. Open the Kibana URL at :samp:`http://<{IP address of the 'lma' node}>/`

#. Open the Notifications dashboard using the 'Load' icon.

#. Enter 'volume_id:<uuid>' in the Query box where <uuid> is the id of the created volume.


Expected Result
:::::::::::::::

All `event types for Cinder <https://docs.google.com/a/mirantis.com/spreadsheets/d/1ES_hWWLpn_eAur2N1FPNyqQAs5U36fQOcuCxRZjHESY/edit?usp=sharing>`_
are listed.
