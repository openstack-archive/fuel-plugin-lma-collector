
+---------------+--------------------------------------------------------------------------+
| Test Case ID  | display_dashboards_in_grafana_ui                                         |
+---------------+--------------------------------------------------------------------------+
| Description   | Verify that the dashboards show up in the Grafana UI.                    |
+---------------+--------------------------------------------------------------------------+
| Prerequisites | Environment deployed with the 4 plugins (see :ref:`deploy_lma_plugins`). |
+---------------+--------------------------------------------------------------------------+

Steps
:::::

#. Open the Grafana URL (open the 'Dashboard' tab and click the 'Grafana' link).

#. Sign-in using the credentials provided during the configuration of the environment.

#. Go to the Main dashboard and verify that everything is ok.

#. Repeat the previous step for the following dashboards:

    a. Cinder

    #. Glance

    #. Heat

    #. Keystone

    #. Nova

    #. Neutron

    #. HAProxy

    #. RabbitMQ

    #. MySQL

    #. Apache

    #. Memcached

    #. System

    #. LMA Self-monitoring

    #. Hypervisor

    #. Elasticsearch

    #. InfluxDB



Expected Result
:::::::::::::::

The Grafana UI shows the overall status of the OpenStack services and detailed
statistics about the selected controller.
