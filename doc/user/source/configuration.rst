.. _config_guide:

Configuration Guide
===================

.. _plugin_configuration:

Plugin configuration
--------------------

To configure your plugin, you need to follow these steps:

1. `Create a new environment <http://docs.mirantis.com/openstack/fuel/fuel-7.0/user-guide.html#launch-wizard-to-create-new-environment>`_ with the Fuel web user interface.

2. Click on the 'Settings' tab of the Fuel web UI and select the 'Other' category.

3. Scroll down through the settings until you find the 'The Logging, Monitoring and
   Alerting (LMA) Collector Plugin' section. You should see a page like this.

.. image:: ../../images/collector_settings.png
   :width: 350pt
   :alt: The LMA Collector settings
   :align: center

4. Tick the 'The Logging, Monitoring and Alerting (LMA) Collector Plugin' box and
   fill-in the required fields as indicated below.

  a. Provide an 'Environment Label' of your choice to tag your data (optional).
  b. For the 'Events Analytics' destination, select 'Local node' if you plan to use the
     Elasticsearch-Kibana Plugin in this environment. Otherwise, select 'Remote server'
     and specify the fully qualified name or IP address of an external Elasticsearch server.
  c. For the 'Metrics Analytics' destination, select 'Local node' if you plan to use the
     InfluxDB-Grafana Plugin in this environment. Otherwise, select 'Remote server' and specify
     the fully qualified name or IP address of an external InfluxDB server. Then, specify the
     InfluxDB database name you want to use, a username and password that has read and write
     access permissions.
  d. For 'Alerting', select 'Alerts sent by email' if you want to receive alerts sent by email
     from the Collector. Otherwise, select 'Alerts sent to a local cluster' if you plan to
     use the Infrastructure Alerting Plugin in this environment.
     Alternatively, you can select 'Alerts sent to a remote Nagios server'.
  e. For 'Alerts sent by email', you can specify the SMTP authentication method you want to use. Then,
     specify the SMTP server fully qualified name or IP address, the SMTP username and password who
     have the permissions to send emails.
  f. Finally, specify the Nagios server URL, username and password if you have chosen to send
     alerts to an external Nagios server.

5. `Configure your environment <http://docs.mirantis.com/openstack/fuel/fuel-8.0/user-guide.html#configure-your-environment>`_ as needed.

6. `Assign roles to the nodes <http://docs.mirantis.com/openstack/fuel/fuel-8.0/user-guide.html#assign-a-role-or-roles-to-each-node-server>`_ for the environment.

7. `Verify networks <http://docs.mirantis.com/openstack/fuel/fuel-8.0/user-guide.html#verify-networks>`_ on the Networks tab of the Fuel web UI.

8. `Deploy <http://docs.mirantis.com/openstack/fuel/fuel-8.0/user-guide.html#deploy-changes>`_ your changes.

.. note:: The *LMA Collector Plugin* is a *hot-pluggable* plugin which means
   that it is possible to install and deploy the *LMA Collector* in an
   environment that is already deployed. After the installation of the *LMA
   Collector* plugin, you need to configure the plugin and run the command
   below from the *Fuel master node* for every OpenStack node of the current
   deployment, starting with the controller nodes::

     [root@nailgun ~]# fuel nodes --env <env_id> --node <node_id> --start \
       post_deployment_start

   If you want to deploy new nodes at the same time (for instance to run
   InfluxDB, Elasticsearch and/or Nagios), you should deploy them first.

.. _plugin_verification:

Plugin verification
-------------------

Once the OpenStack environment is ready, you may want to check that both
the 'collectd' and 'hekad' processes of the LMA Collector are running on the OpenStack nodes::

    [root@node-1 ~]# pidof hekad
    5568
    [root@node-1 ~]# pidof collectd
    5684

.. _troubleshooting:

Troubleshooting
---------------

If you see no data in the Kibana and/or Grafana dashboards, use the instructions below to troubleshoot the problem:

1. Check if the LMA Collector service is up and running::

    # On the controller node(s)
    [root@node-1 ~]# crm resource status lma_collector

    # On non controller nodes
    [root@node-1 ~]# status lma_collector

2. If the LMA Collector is down, restart it::

    # On the controller node(s)
    [root@node-1 ~]# crm resource start lma_collector

    # On non controller nodes
    [root@node-1 ~]# start lma_collector

3. Look for errors in the LMA Collector log file (located at /var/log/lma_collector.log) on the different nodes.

4. Look for errors in the collectd log file (located at /var/log/collectd.log) on the different nodes.

5. Check if the nodes are able to connect to the Elasticsearch server on port 9200.

6. Check if the nodes are able to connect to the InfluxDB server on port 8086.
