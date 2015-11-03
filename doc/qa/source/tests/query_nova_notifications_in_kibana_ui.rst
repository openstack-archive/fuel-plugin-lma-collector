
+---------------+--------------------------------------------------------------------------+
| Test Case ID  | query_nova_notifications_in_kibana_ui                                    |
+---------------+--------------------------------------------------------------------------+
| Description   | Verify that the Nova notifications show up in the Kibana UI.             |
+---------------+--------------------------------------------------------------------------+
| Prerequisites | Environment deployed with the 4 plugins (see :ref:`deploy_lma_plugins`). |
+---------------+--------------------------------------------------------------------------+

Steps
:::::

#. Launch, update, rebuild, resize, power-off, power-on, snapshot, suspend,
   shutdown, and delete an instance in the OpenStack environment (using the
   Horizon dashboard for example) and write down the instance's id.

#. Open the Kibana URL at :samp:`http://<{IP address of the 'lma' node}>/`

#. Open the Notifications dashboard using the 'Load' icon.

#. Enter 'instance_id:<uuid>' in the Query box where <uuid> is the id of the launched instance.


Expected Result
:::::::::::::::

All `event types for Nova <https://docs.google.com/a/mirantis.com/spreadsheets/d/1ES_hWWLpn_eAur2N1FPNyqQAs5U36fQOcuCxRZjHESY/edit?usp=sharing>`_
are listed except compute.instance.create.error and compute.instance.resize.revert.{start|end}.
