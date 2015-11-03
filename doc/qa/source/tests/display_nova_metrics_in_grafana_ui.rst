
+---------------+--------------------------------------------------------------------------+
| Test Case ID  | display_nova_metrics_in_grafana_ui                                       |
+---------------+--------------------------------------------------------------------------+
| Description   | Verify that the Nova metrics show up in the Grafana UI.                  |
+---------------+--------------------------------------------------------------------------+
| Prerequisites | Environment deployed with the 4 plugins (see :ref:`deploy_lma_plugins`). |
+---------------+--------------------------------------------------------------------------+

Steps
:::::

#. Open the Grafana URL at :samp:`http://<{IP address of the 'lma' node}>:8000/`

#. Sign-in using the credentials provided during the configuration of the environment.

#. Go to the Nova dashboard.

#. Connect to the Fuel web UI, launch the full suite of OSTF tests and wait for their completion.

#. Check that the 'instance creation time' graph in the Nova dashboard reports values.


Expected Result
:::::::::::::::

The Grafana UI shows the instance creation time over time.
