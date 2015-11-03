
+---------------+------------------------------------------------------------------------------------+
| Test Case ID  | report_service_alerts_with_critical_severity                                       |
+---------------+------------------------------------------------------------------------------------+
| Description   | Verify that the critical alerts for services show up in the Grafana and Nagios UI. |
+---------------+------------------------------------------------------------------------------------+
| Prerequisites | Environment deployed with the 4 plugins (see :ref:`deploy_lma_plugins`).           |
+---------------+------------------------------------------------------------------------------------+

Steps
:::::

#. Open the Grafana URL at :samp:`http://<{IP address of the 'lma' node}>:8000/`
   and load the Nova dashboard.

#. Open the Nagios URL at :samp:`http://<{IP address of the 'lma' node}>:8001/`
   in another tab and click the 'Services' menu item.

#. Connect to one of the controller nodes using ssh and stop the nova-api service.

#. Connect to a second controller node using ssh and stop the nova-api service.

#. Wait for at least 1 minute.

#. On Grafana, check the following items:

    a. the box in the upper left corner of the dashboard displays 'CRIT' with a red background,

    #. the API panels report 2 entities as down.

#. On Nagios, check the following items:

    a. the 'nova' service is in 'CRITICAL' state,

    #. the local user root on the lma node has received an email about the service being in critical state.

#. Restart the nova-api service on both nodes.

#. Wait for at least 1 minute.

#. On Grafana, check the following items:

    a. the box in the upper left corner of the dashboard displays 'OKAY' with an green background,

    #. the API panels report 0 entity as down.

#. On Nagios, check the following items:

    a. the 'nova' service is in 'OK' state,

    #. the local user root on the lma node has received an email about the recovery of the service.

#. Connect to one of the controller nodes using ssh and stop the nova-scheduler service.

#. Connect to a second controller node using ssh and stop the nova-scheduler service.

#. Wait for at least 3 minutes.

#. On Grafana, check the following items:

    a. the box in the upper left corner of the dashboard displays 'CRIT' with a red background,

    #. the scheduler panel reports 2 entities as down.

#. On Nagios, check the following items:

    a. the 'nova' service is in 'CRITICAL' state,

    #. the local user root on the lma node has received an email about the service being in critical state.

#. Restart the nova-scheduler service on both nodes.

#. Wait for at least 1 minute.

#. On Grafana, check the following items:

    a. the box in the upper left corner of the dashboard displays 'OKAY' with an green background,

    #. the scheduler panel reports 0 entity as down.

#. On Nagios, check the following items:

    a. the 'nova' service is in 'OK' state,

    #. the local user root on the lma node has received an email about the recovery of the service.

#. Repeat steps 2 to 21 for the following services:

    a. Cinder (stopping and starting the cinder-api and cinder-scheduler services respectively).

    #. Neutron (stopping and starting the neutron-server and neutron-openvswitch-agent services respectively).

#. Repeat steps 2 to 11 for the following services:

    a. Glance (stopping and starting the glance-api service).

    #. Heat (stopping and starting the heat-api service).

    #. Keystone (stopping and starting the Apache service).


Expected Result
:::::::::::::::

The Grafana UI shows that the global service status goes from ok to critical and
back to ok. It also reports detailed information about which entity is missing.

The Nagios UI shows that the service status goes from ok to critical and back to
ok. Alerts are sent by email to the configured recipient.
