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
      :width: 400pt
      :alt: The StackLight Collector Plugin settings

#. Select :guilabel:`The Logging, Monitoring and Alerting (LMA) Collector
   Plugin` and fill in the required fields as indicated below.

   a. Optional. Provide an :guilabel:`Environment Label` of your choice to tag
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

#. Configure your environment as described in `Configure your environment
   <http://docs.openstack.org/developer/fuel-docs/userdocs/fuel-user-guide/configure-environment.html>`__.

   .. note:: By default, StackLight is configured to use the *management
      network* of the so-called *default node network group* created by Fuel.
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
      StackLight Collector Plugin, define the settings of the plugin and
      run the commands shown below from the *Fuel master node* for every
      node of your deployment starting with *the controller node(s)*:

      .. code-block:: console

         [root@nailgun ~]# fuel nodes --env <env_id> --node <node_id> --tasks hiera install-ocf-script

      Once the task has completed for the node, run the following command:

      .. code-block:: console

         [root@nailgun ~]# fuel nodes --env <env_id> --node <node_id> --start post_deployment_start

.. _plugin_verification:

.. raw:: latex

   \pagebreak

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

#. Verify that the *collector* services are up and running:

   * On the controller nodes:

     .. code-block:: console

        [root@node-1 ~]# crm resource status metric_collector
        [root@node-1 ~]# crm resource status log_collector

   * On non-controller nodes:

     .. code-block:: console
   
        [root@node-2 ~]# status log_collector
        [root@node-2 ~]# status metric_collector

#. If a *collector* is down, restart it:

   * On the controller nodes:

     .. code-block:: console

        [root@node-1 ~]# crm resource start log_collector
        [root@node-1 ~]# crm resource start metric_collector

   * On non-controller nodes:

     .. code-block:: console

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

.. _advanced_configuration:

Advanced configuration
----------------------

Due to a current limitation in Fuel, when a node is removed from an OpenStack
environment through the Fuel web UI or CLI, the services that were running on
that node are not automatically removed from the database. Therefore,
StackLight reports these services as failed. To resolve this issue, remove
these services manually.

**To reconfigure the StackLight Collector after removing a node:**

#. From a controller node, list the services that are reported failed. In the
   example below, it is ``node-7``.

   .. code-block:: console

    root@node-6:~# source ./openrc
    root@node-6:~# neutron agent-list
    +--------------+-------------------+-------------------+-------------------+-------+
    | id           | agent_type        | host              | availability_zone | alive |
    +--------------+-------------------+-------------------+-------------------+-------+
    | 08a69bad-... | Metadata agent    | node-8.domain.tld |                   | :-)   |
    | 11b6dca6-... | Metadata agent    | node-7.domain.tld |                   | xxx   |
    | 22ea82e3-... | DHCP agent        | node-6.domain.tld | nova              | :-)   |
    | 2d82849e-... | L3 agent          | node-6.domain.tld | nova              | :-)   |
    | 3221ec18-... | Open vSwitch agent| node-6.domain.tld |                   | :-)   |
    | 84bfd240-... | Open vSwitch agent| node-7.domain.tld |                   | xxx   |
    | 9452e8f0-... | Open vSwitch agent| node-9.domain.tld |                   | :-)   |
    | 97136b09-... | Open vSwitch agent| node-8.domain.tld |                   | :-)   |
    | c198bc94-... | DHCP agent        | node-7.domain.tld | nova              | xxx   |
    | c76c4ed4-... | L3 agent          | node-7.domain.tld | nova              | xxx   |
    | d0fd8bb5-... | L3 agent          | node-8.domain.tld | nova              | :-)   |
    | d21f9cea-... | DHCP agent        | node-8.domain.tld | nova              | :-)   |
    | f6f871b7-... | Metadata agent    | node-6.domain.tld |                   | :-)   |
    +--------------+-------------------+-------------------+-------------------+-------+
    root@node-6:~# nova service-list
    +--+----------------+-----------------+---------+--------+-------+-----------------+
    |Id|Binary          |Host             | Zone    | Status | State |   Updated_at    |
    +--+----------------+-----------------+---------+--------+-------+-----------------+
    |1 |nova-consoleauth|node-6.domain.tld| internal| enabled| up    | 2016-07-19T11:43|
    |4 |nova-scheduler  |node-6.domain.tld| internal| enabled| up    | 2016-07-19T11:43|
    |7 |nova-cert       |node-6.domain.tld| internal| enabled| up    | 2016-07-19T11:43|
    |10|nova-conductor  |node-6.domain.tld| internal| enabled| up    | 2016-07-19T11:42|
    |22|nova-cert       |node-7.domain.tld| internal| enabled| down  | 2016-07-19T11:43|
    |25|nova-consoleauth|node-7.domain.tld| internal| enabled| down  | 2016-07-19T11:43|
    |28|nova-scheduler  |node-7.domain.tld| internal| enabled| down  | 2016-07-19T11:43|
    |31|nova-cert       |node-8.domain.tld| internal| enabled| up    | 2016-07-19T11:43|
    |34|nova-consoleauth|node-8.domain.tld| internal| enabled| up    | 2016-07-19T11:43|
    |37|nova-conductor  |node-7.domain.tld| internal| enabled| down  | 2016-07-19T11:42|
    |43|nova-scheduler  |node-8.domain.tld| internal| enabled| up    | 2016-07-19T11:43|
    |49|nova-conductor  |node-8.domain.tld| internal| enabled| up    | 2016-07-19T11:42|
    |64|nova-compute    |node-9.domain.tld| nova    | enabled| up    | 2016-07-19T11:42|
    +--+----------------+-----------------+---------+--------+-------+-----------------+
    root@node-6:~# cinder service-list
    +----------------+-----------------------------+----+-------+-----+----------------+
    |    Binary      |            Host             |Zone| Status|State|   Updated_at   |
    +----------------+-----------------------------+----+-------+-----+----------------+
    |cinder-backup   |       node-9.domain.tld     |nova|enabled|up   |2016-07-19T11:44|
    |cinder-scheduler|       node-6.domain.tld     |nova|enabled|up   |2016-07-19T11:43|
    |cinder-scheduler|       node-7.domain.tld     |nova|enabled|down |2016-07-19T11:43|
    |cinder-scheduler|       node-8.domain.tld     |nova|enabled|up   |2016-07-19T11:44|
    |cinder-volume   |node-9.domain.tld@LVM-backend|nova|enabled|up   |2016-07-19T11:44|
    +----------------+-----------------------------+----+-------+-----+----------------+

#. Remove the services and/or agents that are reported failed on that node:

   .. code-block:: console

      root@node-6:~# nova service-delete <id of service to delete>
      root@node-6:~# cinder service-disable <hostname> <binary>
      root@node-6:~# neutron agent-delete <id of agent to delete>

#. Restart the Collector on all the controller nodes:

   .. code-block:: console

      [root@node-1 ~]# crm resource restart log_collector
      [root@node-1 ~]# crm resource restart metric_collector
