
+---------------+---------------------------------------------------------------------------------+
| Test Case ID  | deploy_lma_plugins                                                              |
+---------------+---------------------------------------------------------------------------------+
| Description   | Verify that the plugins can be deployed.                                        |
+---------------+---------------------------------------------------------------------------------+
| Prerequisites | Plugins are installed on the Fuel master node (see :ref:`install_lma_plugins`). |
+---------------+---------------------------------------------------------------------------------+

Steps
:::::

#. Connect to the Fuel web UI.

#. Create a new environment with the Fuel UI wizard with the default settings.

#. Click on the Settings tab of the Fuel web UI.

#. Select the LMA collector plugin tab and fill-in the following fields:

    a. Enable the plugin.

    #. Select 'Local node' for "Event analytics".

    #. Select 'Local node' for "Metric analytics".

    #. Select 'Alerts sent to a local node running the LMA Infrastructure Alerting plugin' for "Alerting".

#. Select the Elasticsearch-Kibana plugin tab and enable it.

#. Select the InfluxDB-Grafana plugin and fill-in the required fields:

    a. Enable the plugin.

    #. Enter 'lmapass' as the root, user and grafana user passwords.

#. Select the LMA Infrastructure-Alerting plugin and fill-in the required fields:

    a. Enable the plugin.

    #. Enter 'root\@localhost' as the recipient

    #. Enter 'nagios\@localhost' as the sender

    #. Enter '127.0.0.1' as the SMTP server address

    #. Choose "None" for SMTP authentication (default)

#. Click on the Nodes tab of the Fuel web UI.

#. Assign roles to nodes:

    a. 1 node with these 3 roles (this node is referenced later as the 'lma' node):

        i. influxdb_grafana

        #. elasticsearch_kibana

        #. infrastructure_alerting

    #. 3 nodes with the 'controller' role

    #. 1 node with the 'compute' + 'cinder' node

#. Click 'Deploy changes'.

#. Once the deployment has finished, connect to each node of the environment using ssh and run the following checks:

    a. Check that hekad and collectd processes are up and running on all the nodes as described in the `LMA Collector documentation <http://fuel-plugin-lma-collector.readthedocs.org/en/stable/user/configuration.html#plugin-verification>`_.

    #. Look for errors in /var/log/lma_collector.log

    #. Check that the node can connect to the Elasticsearch server (:samp:`http://<{IP address of the 'lma' node}>:9200/`)

    #. Check that the node can connect to the InfluxDB server (:samp:`http://<{IP address of the 'lma' node}>:8086/`)

#. Check that the dashboards are running

    a. Check that you can connect to the Kibana UI (:samp:`http://<{IP address of the 'lma' node}>:80/`)
    #. Check that you can connect to the Grafana UI (:samp:`http://<{IP address of the 'lma' node}>:8000/`) with user='grafana', password='lmapass'
    #. Check that you can connect to the Nagios UI (:samp:`http://<{IP address of the 'lma' node}>:8001/`) with user='nagiosadmin', password='r00tme'


Expected Result
:::::::::::::::

The environment is deployed successfully.
