
+---------------+--------------------------------------------------------------------------------+
| Test Case ID  | report_node_alerts_with_warning_severity                                       |
+---------------+--------------------------------------------------------------------------------+
| Description   | Verify that the warning alerts for nodes show up in the Grafana and Nagios UI. |
+---------------+--------------------------------------------------------------------------------+
| Prerequisites | Environment deployed with the 4 plugins (see :ref:`deploy_lma_plugins`).       |
+---------------+--------------------------------------------------------------------------------+

Steps
:::::

#. Open the Grafana URL at :samp:`http://<{IP address of the 'lma' node}>:8000/`
   and load the MySQL dashboard.

#. Open the Nagios URL at :samp:`http://<{IP address of the 'lma' node}>:8001/`
   in another tab and click the 'Services' menu item.

#. Connect to one of the controller nodes using ssh and run::

    fallocate -l $(df | grep /dev/mapper/mysql-root | awk '{ printf("%.0f\n", 1024 * ((($3 + $4) * 96 / 100) - $3))}') /var/lib/mysql/test

#. Wait for at least 1 minute.

#. On Grafana, check the following items:

    a. the box in the upper left corner of the dashboard displays 'OKAY' with an green background,

#. On Nagios, check the following items:

    a. the 'mysql' service is in 'OK' state,

    #. the 'mysql-nodes.mysql-fs' service is in 'WARNING' state for the node.

#. Connect to a second controller node using ssh and run::

    fallocate -l $(df | grep /dev/mapper/mysql-root | awk '{ printf("%.0f\n", 1024 * ((($3 + $4) * 96 / 100) - $3))}') /var/lib/mysql/test

#. Wait for at least 1 minute.

#. On Grafana, check the following items:

    a. the box in the upper left corner of the dashboard displays 'WARN' with an orange background,

    #. an annotation telling that the service went from 'OKAY' to 'WARN' is displayed.

#. On Nagios, check the following items:

    a. the 'mysql' service is in 'WARNING' state,

    #. the 'mysql-nodes.mysql-fs' service is in 'WARNING' state for the 2 nodes,

    #. the local user root on the lma node has received an email about the service being in warning state.

#. Run the following command on both controller nodes::

    rm /var/lib/mysql/test

#. Wait for at least 1 minute.

#. On Grafana, check the following items:

    a. the box in the upper left corner of the dashboard displays 'OKAY' with an green background,

    #. an annotation telling that the service went from 'WARN' to 'OKAY' is displayed.

#. On Nagios, check the following items:

    a. the 'mysql' service is in 'OK' state,

    #. the 'mysql-nodes.mysql-fs' service is in 'OKAY' state for the 2 nodes,

    #. the local user root on the lma node has received an email about the recovery of the service.


Expected Result
:::::::::::::::

The Grafana UI shows that the global 'mysql' status goes from ok to warning and
back to ok. It also reports detailed information about the problem in the annotations.

The Nagios UI shows that the service status goes from ok to warning and back to
ok. Alerts are sent by email to the configured recipient.
