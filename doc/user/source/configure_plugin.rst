.. _plugin_configuration:

Plugin configuration
--------------------

**To configure the StackLight Collector plugin:**

#. Create a new environment as described in `Create a new OpenStack environment
   <http://docs.openstack.org/developer/fuel-docs/userdocs/fuel-user-guide/create-environment/start-create-env.html>`__.

#. In the Fuel web UI, click the :guilabel:`Settings` tab and select the
   :guilabel:`Other` category.

#. Scroll down through the settings until you find the StackLight Collector
   Plugin section. You should see a page like this:

   .. image:: ../../images/collector_settings.png
      :width: 350pt
      :alt: The StackLight Collector Plugin settings

#. Select :guilabel:`The Logging, Monitoring and Alerting (LMA) Collector
   Plugin` and fill in the required fields as indicated below.

   #. Optional. Provide an :guilabel:`Environment Label` of your choice to tag
      your data.
   #. In the :guilabel:`Events Analytics` section, select
      :guilabel:`Local node` if you plan to use the Elasticsearch-Kibana
      Plugin in the environment. Otherwise, select :guilabel:`Remote server`
      and specify the fully qualified name or the IP address of an external
      Elasticsearch server.
   #. In the :guilabel:`Metrics Analytics` section, select
      :guilabel:`Local node` if you plan to use the InfluxDB-Grafana Plugin in
      the environment. Otherwise, select :guilabel:`Remote server` and specify
      the fully qualified name or the IP address of an external InfluxDB
      server. Then, specify the InfluxDB database name you want to use, a
      username and password that have read and write access permissions.
   #. In the :guilabel:`Alerting` section, select
      :guilabel:`Alerts sent by email` if you want to receive alerts sent by
      email from the Collector. Otherwise, select
      :guilabel:`Alerts sent to a local cluster` if you plan to use the
      Infrastructure Alerting Plugin (Nagios) in the environment.
      Alternatively, select :guilabel:`Alerts sent to a remote Nagios server`.
   #. For :guilabel:`Alerts sent by email`, specify the SMTP authentication
      method you want to use. Then, specify the SMTP server fully qualified
      name or IP address, the SMTP username and password to have the
      permissions to send emails.
   #. Specify the Nagios server URL, username, and password if you have chosen
      to send alerts to an external Nagios server.

#. Configure your environment as described in `Configure your Environment
   <http://docs.openstack.org/developer/fuel-docs/userdocs/fuel-user-guide/configure-environment.html>`__.

   .. note:: By default, StackLight is configured to use the *management
      network*, of the so-called *default node network group* created by Fuel.
      While this default setup may be appropriate for small deployments or
      evaluation purposes, it is recommended that you not use the default
      *management network* for StackLight. Instead, create a dedicated network
      when configuring your environment. This will improve the overall
      performance of both OpenStack and StackLight and facilitate the access
      to the Kibana and Grafana analytics.

#. Deploy your environment as described in `Deploy an OpenStack environment
   <http://docs.openstack.org/developer/fuel-docs/userdocs/fuel-user-guide/deploy-environment.html>`__.

   .. note:: The StackLight Collector Plugin is a *hot-pluggable* plugin.
      Therefore, it is possible to install and deploy the *collector* in an
      environment that is already deployed. After the installation of the
      StackLight Collector Plugin, you will need to define the settings of the
      plugin and then run the command shown below from the *Fuel master node*
      for every node of your deployment. You need to start with
      *the controller node(s)*:

      .. code-block:: console

         [root@nailgun ~]# fuel nodes --env <env_id> --node <node_id> --start \
           post_deployment_start --tasks hiera

.. _plugin_verification:

Plugin verification
-------------------

Once the OpenStack environment is ready, verify that both the *collectd* and
*hekad* processes are running on the OpenStack nodes:

.. code-block:: console

   [root@node-1 ~]# pidof hekad
   5568
   5569
   [root@node-1 ~]# pidof collectd
   5684

.. note:: Starting with StackLight version 0.10, there are two *hekad*
   processes running instead of one. One is used to collect and process the
   logs and the notifications, the other one is used to process the metrics.

.. _troubleshooting:

Troubleshooting
---------------

If you see no data in the Kibana and/or Grafana dashboards, follow the
instructions below to troubleshoot the issue:

#. Verify that the *collector* services are up and running::

    # On the controller node(s)
    [root@node-1 ~]# crm resource status metric_collector
    [root@node-1 ~]# crm resource status log_collector

    # On non controller nodes
    [root@node-2 ~]# status log_collector
    [root@node-2 ~]# status metric_collector

#. If a *collector* is down, restart it::

    # On the controller node(s)
    [root@node-1 ~]# crm resource start log_collector
    [root@node-1 ~]# crm resource start metric_collector

    # On non controller nodes
    [root@node-2 ~]# start log_collector
    [root@node-2 ~]# start metric_collector

#. Look for errors in the log file of the *collectors* located at
   ``/var/log/log_collector.log`` and ``/var/log/metric_collector.log``.

#. Look for errors in the log file of *collectd* located at
   ``/var/log/collectd.log``.

#. Verify that the nodes are able to connect to the Elasticsearch server on port
   9200.

#. Verify that the nodes are able to connect to the InfluxDB server on port 8086.

.. _diagnostic:

Diagnostic tool
---------------

The StackLight Collector Plugin installs a **global diagnostic tool** on the
Fuel Master node. The global diagnostic tool checks that StackLight is
configured and running properly across the entire LMA toolchain for all the
nodes that are ready in your OpenStack environment:

.. code-block:: console

   [root@nailgun ~]# /var/www/nailgun/plugins/lma_collector-<version>/contrib/tools/diagnostic.sh
   Running lma_diagnostic tool on all available nodes (this can take several minutes)
   The diagnostic archive is here: /var/lma_diagnostics.2016-06-10_11-23-1465557820.tgz

.. note:: A global diagnostic can take several minutes.

All the results are consolidated in the
``/var/lma_diagnostics.[date +%Y-%m-%d_%H-%M-%s].tgz`` archive.

Instead of running a global diagnostic, you may want to run the diagnostic
on individual nodes. Based on the role of the node, the tool determines what
checks should be executed. For example:

.. code-block:: console

   root@node-3:~# hiera roles
   ["controller"]

   root@node-3:~# lma_diagnostics

   2016-06-10-11-08-04 INFO node-3.test.domain.local role ["controller"]
   2016-06-10-11-08-04 INFO ** LMA Collector
   2016-06-10-11-08-04 INFO 2 process(es) 'hekad -config' found
   2016-06-10-11-08-04 INFO 1 process(es) hekad is/are listening on port 4352
   2016-06-10-11-08-04 INFO 1 process(es) hekad is/are listening on port 8325
   2016-06-10-11-08-05 INFO 1 process(es) hekad is/are listening on port 5567
   2016-06-10-11-08-05 INFO 1 process(es) hekad is/are listening on port 4353
   [...]

In the example above, the diagnostic tool reports that two *hekad* processes
are running on *node-3*, which is the expected outcome. In the case when one
*hekad* process is not running, the diagnostic tool reports an error. For
example:

.. code-block:: console

   root@node-3:~# lma_diagnostics
   2016-06-10-11-11-48 INFO node-3.test.domain.local role ["controller"]
   2016-06-10-11-11-48 INFO ** LMA Collector
   2016-06-10-11-11-48 ERROR 1 'hekad -config' processes found, 2 expected!
   2016-06-10-11-11-48 ERROR 'hekad' process does not LISTEN on port: 4352
   [...]

In the example above, the diagnostic tool reported two errors:

  #. There is only one *hekad* process running instead of two.
  #. No *hekad* process is listening on port 4352.

These examples describe only one type of checks performed by the diagnostic
tool, but there are many others.

On the OpenStack nodes, the diagnostic results are stored in ``/var/lma_diagnostics/diagnostics.log``.

.. note:: A successful LMA toolchain diagnostic should be free of errors.
