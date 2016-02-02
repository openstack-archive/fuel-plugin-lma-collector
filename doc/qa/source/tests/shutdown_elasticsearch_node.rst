+---------------+----------------------------------------------------------------------------------+
| Test Case ID  | shutdown_elasticsearch_node                                                      |
+---------------+----------------------------------------------------------------------------------+
| Description   | Verify that failover for Elasticsearch cluster works.                            |
+---------------+----------------------------------------------------------------------------------+
| Prerequisites | Environment deployed with the 4 plugins (See :ref:`deploy_lma_plugins_ha_mode`). |
+---------------+----------------------------------------------------------------------------------+

Steps
:::::

#. Connect to any elasticsearch_kibana node and run command 'crm status'.

#. Shutdown node were vip_es_vip_mgmt was started.

#. Check that vip_elasticsearch was started on another influxdb node.

#. Check the plugin services using cli.

#. Check that Kibana UI works correctly.

#. Check that no data lost after shutdown.

#. Run OSTF.


Expected Result
:::::::::::::::

The OSTF tests pass successfully.

All the plugin services are running and work as expected after each
modification of the environment.

vip_es_vip_mgmt was started on another node after shutdown.
