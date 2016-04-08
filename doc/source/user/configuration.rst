.. _config_guide:

Configuration Guide
===================

.. _plugin_configuration:

Plugin configuration
--------------------

To configure your plugin, you need to follow the following steps:

1. `Create a new environment <http://docs.mirantis.com/openstack/fuel/fuel-7.0/user-guide.html#launch-wizard-to-create-new-environment>`_ with the Fuel web user interface.

2. Click on the Settings tab of the Fuel web UI.

3. Select the LMA collector plugin in the left column. The LMA Collector settings screen appears.

.. image:: ../../images/collector_settings.png
   :scale: 50 %
   :alt: The LMA Collector settings
   :align: center

4. Select the LMA collector plugin checkbox and fill-in the required fields.

  a. Select "Local node" for Events analytics if you deploy the Elasticsearch-Kibana plugin on a dedicated node in the same environment.
  b. Select "Remote server" for Events analytics if you have an Elasticsearch-Kibana server already deployed and running.
     In that case, you have to enter the IP address or the fully qualified name of the server.
  c. Select "Local node" for Metrics analytics if you deploy the InfluxDB-Grafana plugin on a dedicated node in the same environment.
  d. Select "Remote server" for Metrics analytics if you have an InfluxDB-Grafana server already deployed and running.
     In that case, you have to enter the IP address or the fully qualified name of the server as well as the credentials and database to store the metrics.
  e. Select "Alerts sent by email" for Alerting if you wish to receive alerts by email.
  f. Select "Alerts sent to a local node" for Alerting if you deploy the LMA Infrastructure Alerting plugin on a dedicated node in the same environment.
  g. Select "Alerts sent to a remote Nagios server" for Alerting if you have a Nagios server already deployed and running.

5. `Configure your environment <http://docs.mirantis.com/openstack/fuel/fuel-7.0/user-guide.html#configure-your-environment>`_ as needed.

6. `Assign roles to the nodes <http://docs.mirantis.com/openstack/fuel/fuel-7.0/user-guide.html#assign-a-role-or-roles-to-each-node-server>`_ for the environment.

7. `Verify networks <http://docs.mirantis.com/openstack/fuel/fuel-7.0/user-guide.html#verify-networks>`_ on the Networks tab of the Fuel web UI.

8. `Deploy <http://docs.mirantis.com/openstack/fuel/fuel-7.0/user-guide.html#deploy-changes>`_ your changes.

.. _plugin_verification:

Plugin verification
-------------------

Once the OpenStack environment is ready, you may want to check that both
collectd and hekad processes are running on the controller nodes::

    [root@node-1 ~]# pidof hekad
    5568
    [root@node-1 ~]# pidof collectd
    5684

Please refer to the :ref:`troubleshooting` section otherwise.

.. _troubleshooting:

Troubleshooting
---------------

If you see no data in the Kibana and/or Grafana dashboards, use the instructions below to troubleshoot the problem:

1. Check if the LMA collector service is up and running::

    # On the controller nodes
    [root@node-1 ~]# crm resource status lma_collector

    # On nodes which are not controllers
    [root@node-1 ~]# status lma_collector

2. If the LMA Collector is down, restart it::

    # On the controller nodes
    [root@node-1 ~]# crm resource start lma_collector

    # On nodes which are not controllers
    [root@node-1 ~]# status lma_collector

3. Look for errors in the LMA Collector log file (located at /var/log/lma_collector.log) on the different nodes.

4. Look for errors in the collectd log file (located at /var/log/collectd.log) on the different nodes.

5. Check if the nodes are able to connect to the Elasticsearch server on port 9200.

6. Check if the nodes are able to connect to the InfluxDB server on port 8086.
