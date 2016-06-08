.. _config_guide:

Configuration Guide
===================

.. _plugin_configuration:

Plugin configuration
--------------------

To configure your plugin, you need to follow these steps:

1. Create a new environment following the `instruction
   <http://docs.openstack.org/developer/fuel-docs/userdocs/fuel-user-guide/create-environment/start-create-env.html>`_
   of the Fuel User Guide.

2. Click on the _Settings_ tab of the Fuel web UI and select the _Other_ category.

3. Scroll down through the settings until you find the StackLight Collector
   Plugin section. You should see a page like this.

.. image:: ../../images/collector_settings.png
   :width: 350pt
   :alt: The StackLight Collector Plugin settings
   :align: center

4. Tick the StackLight Collector Plugin box and
   fill-in the required fields as indicated below.

  a. Provide an _Environment Label_ of your choice to tag your data (optional).
  b. For the _Events Analytics_ destination, select _Local node_ if you plan to use the
     Elasticsearch-Kibana Plugin in the  environment. Otherwise, select _Remote server_
     and specify the fully qualified name or IP address of an external Elasticsearch server.
  c. For the _Metrics Analytics_ destination, select _Local node_ if you plan to use the
     InfluxDB-Grafana Plugin in the environment. Otherwise, select _Remote server_ and specify
     the fully qualified name or IP address of an external InfluxDB server. Then, specify the
     InfluxDB database name you want to use, a username and password that have read and write
     access permissions.
  d. For _Alerting_, select _Alerts sent by email_ if you want to receive alerts sent by email
     from the Collector. Otherwise, select _Alerts sent to a local cluster_ if you plan to
     use the Infrastructure Alerting Plugin (Nagios) in the environment.
     Alternatively, you can select _Alerts sent to a remote Nagios server_.
  e. For _Alerts sent by email_, you can specify the SMTP authentication method you want to use. Then,
     specify the SMTP server fully qualified name or IP address, the SMTP username and password who
     have the permissions to send emails.
  f. Finally, specify the Nagios server URL, username and password if you have chosen to send
     alerts to an external Nagios server.

5. Configure your environment following the `instructions
   <http://docs.openstack.org/developer/fuel-docs/userdocs/fuel-user-guide/configure-environment.html>`_
   of the Fuel User Guide.

.. note:: By default, StackLight is configured to use the _management network_,
   of the so called _default node network group_ created by Fuel.
   While this default setup may be appropriate for small deployments or
   evaluation purposes, it is recommended not to use the default _management network_
   for StackLight but instead create a dedicated network when configuring your environement.
   This will improve the performance of both OpenStack and StackLight overall and facilitate
   the access to the Kibana and Grafana analytics.
   Please refer to the `StackLight Planning Guide
   <http://foobar.com/>`_ for further information about
   that subject. 

6. Deploy your environment following the `instructions
   <http://docs.openstack.org/developer/fuel-docs/userdocs/fuel-user-guide/deploy-environment.html>`_
   of the Fuel User Guide.

.. note:: The StackLight Collector Plugin is a *hot-pluggable* plugin which means
   that it is possible to install and deploy the _collector_ in an
   environment that is already deployed. After the installation of the StackLight
   Collector Plugin, you will need to define the settings of the plugin and then
   run the command shown below from the _Fuel master node_ for every node of
   your deployment. You need to start with *the controller node(s)*::

     [root@nailgun ~]# fuel nodes --env <env_id> --node <node_id> --start \
       post_deployment_start

   If you also want to install the other plugins of the toolchain, like the
   StackLight InfluxDB-Grafana Plugin or the Stacklight Elasticsearch-Kibana Plugin,
   after an initial deployment, you will need to install and deploy those before
   the StackLight Collector Plugin.

.. _plugin_verification:

Plugin verification
-------------------

Once the OpenStack environment is ready, you should check that both
the _collectd_ and _hekad_ processes are running on the OpenStack nodes::

    [root@node-1 ~]# pidof hekad
    5568
    5569
    [root@node-1 ~]# pidof collectd
    5684

.. note:: Starting with StackLight version 0.10, there is not one but two _hekad_ processes
   running. One is used to collect and process the logs and the notifications, the
   other one is used to process the metrics.

.. _troubleshooting:

Troubleshooting
---------------

If you see no data in the Kibana and/or Grafana dashboards,
use the instructions below to troubleshoot the problem:

1. Check that the _collector_ services are up and running::

    # On the controller node(s)
    [root@node-1 ~]# crm resource status metric_collector
    [root@node-1 ~]# crm resource status log_collector

    # On non controller nodes
    [root@node-2 ~]# status log_collector
    [root@node-2 ~]# status metric_collector

2. If a _collector_ is down, restart it::

    # On the controller node(s)
    [root@node-1 ~]# crm resource start log_collector
    [root@node-1 ~]# crm resource start metric_collector

    # On non controller nodes
    [root@node-2 ~]# start log_collector
    [root@node-2 ~]# start metric_collector

3. Look for errors in the log file of the _collectors_
   (located at /var/log/log_collector.log and /var/log/metric_collector.log).

4. Look for errors in the log file of _collectd_ (located at /var/log/collectd.log).

5. Check if the nodes are able to connect to the Elasticsearch server on port 9200.

6. Check if the nodes are able to connect to the InfluxDB server on port 8086.
