+---------------+----------------------------------------------------------------------+
| Test Case ID  | shutdown_elasticsearch_node                                          |
+---------------+----------------------------------------------------------------------+
| Description   | Verify that failover for Elasticsearch cluster works.                |
+---------------+----------------------------------------------------------------------+
| Prerequisites | Environment deployed with the 4 plugins (See :ref:`deploy_ha_mode`). |
+---------------+----------------------------------------------------------------------+

Steps
:::::

#. Connect to any elasticsearch_kibana node and run command 'crm status'.

#. Run command 'curl -XGET 'http://{vip_es_vip_mgmt}:9200/_cat/indices?v'' and save the output.

#. Shutdown the node were vip_es_vip_mgmt was started.

#. Check that vip_es_vip_mgmt was started on another elasticsearch_kibana node.

#. Check that cluster status became 'WARNING'.

#. Check the plugin services using CLI.

#. Check that Kibana UI works correctly.

#. Run command 'curl -XGET 'http://{vip_es_vip_mgmt}:9200/_cat/indices?v'' one more time and compare this output with the first output.

#. Run OSTF.

#. Start the node.

#. After few minutes check that the cluster status is 'OKAY'.


Expected Result
:::::::::::::::

The OSTF tests pass successfully.

All the plugin services are running and work as expected after each
modification of the environment.

vip_es_vip_mgmt was started on another node after shutdown.

The number of documents in the second output must be equal or greather than in the first output.

There is no gap in the time line in the Kibana dashboards.


