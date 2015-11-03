
+---------------+--------------------------------------------------------------------------+
| Test Case ID  | report_alerts_in_grafana_and_nagios_ui                                   |
+---------------+--------------------------------------------------------------------------+
| Description   | Verify that the alerts show up in the Grafana and Nagios UI.             |
+---------------+--------------------------------------------------------------------------+
| Prerequisites | Environment deployed with the 4 plugins (see :ref:`deploy_lma_plugins`). |
+---------------+--------------------------------------------------------------------------+

Steps
:::::

#. Open the Grafana URL at :samp:`http://<{IP address of the 'lma' node}>:8000/`
   and load the Nova dashboard.

#. Open the Nagios URL at :samp:`http://<{IP address of the 'lma' node}>:8001/`
   in another tab and click the 'Services' menu item.

#. Connect to one of the controller nodes using ssh and stop the nova-api service.

#. Wait for at least 1 minute.

#. On Grafana, check the following items:

    a. the box in the upper left corner of the dashboard displays 'WARN' with an orange background,

    #. the API panels report 1 entity as down.

#. On Nagios, check the following items:

    a. the 'nova' service is in 'WARNING' state,

    #. the local user root on the lma node has received an email about the service being in warning state.

#. Restart the nova-api service.

#. Wait for at least 1 minute.

#. On Grafana, check the following items:

    a. the box in the upper left corner of the dashboard displays 'OKAY' with an green background,

    #. the API panels report 0 entity as down.

#. On Nagios, check the following items:

    a. the 'nova' service is in 'OK' state,

    #. the local user root on the lma node has received an email about the recoovery of the service.

#. Stop the nova-scheduler service.

#. Wait for at least 3 minutes.

#. On Grafana, check the following items:

    a. the box in the upper left corner of the dashboard displays 'WARN' with an orange background,

    #. the scheduler panel reports 1 entity as down.

#. On Nagios, check the following items:

    a. the 'nova' service is in 'WARNING' state,

    #. the local user root on the lma node has received an email about the service being in warning state.

#. Restart the nova-scheduler service.

#. Wait for at least 1 minute.

#. On Grafana, check the following items:

    a. the box in the upper left corner of the dashboard displays 'OKAY' with an green background,

    #. the scheduler panel reports 0 entity as down.

#. On Nagios, check the following items:

    a. the 'nova' service is in 'OK' state,

    #. the local user root on the lma node has received an email about the recoovery of the service.

#. Repeat steps 2 to 18 for the following services:

    a. Cinder (stopping and starting the cinder-api and cinder-scheduler services respectively).

    #. Neutron (stopping and starting the neutron-server and neutron-openvswitch-agent services respectively).

#. Repeat steps 2 to 10 for the following services:

    a. Glance (stopping and starting the glance-api service).

    #. Heat (stopping and starting the heat-api service).

    #. Keystone (stopping and starting the Apache service).


Expected Result
:::::::::::::::

The Grafana UI shows that the global service status goes from ok to warning and
back to ok. It also reports detailed information about which entity is missing.

The Nagios UI shows that the service status goes from ok to warning and back to
ok. Alerts are sent by email to the configured recipient.
