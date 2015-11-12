
+---------------+--------------------------------------------------------------------------+
| Test Case ID  | network_failure_on_analytics_node                                        |
+---------------+--------------------------------------------------------------------------+
| Description   | Verify that the backends and dashboards recover after a network failure. |
+---------------+--------------------------------------------------------------------------+
| Prerequisites | Environment deployed with the 4 plugins (see :ref:`deploy_lma_plugins`). |
+---------------+--------------------------------------------------------------------------+

Steps
:::::

#. Copy this script to the analytics node::

    #!/bin/sh
    /sbin/iptables -I INPUT -j DROP
    sleep 30
    /sbin/iptables -D INPUT -j DROP

#. Login to the analytics node using SSH

#. Run the script and wait for it to complete.

#. Check that the Kibana, Grafana and Nagios dashboards are available.

#. Check that data continues to be pushed by the various nodes once the network failure has ended.



Expected Result
:::::::::::::::

The collectors recover from the network outage of the analytics node.
