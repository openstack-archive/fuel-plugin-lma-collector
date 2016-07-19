.. _Elasticsearch:

The following metrics represent the simple status on the health of the cluster.
For details, see `Cluster health <https://www.elastic.co/guide/en/elasticsearch/reference/1.7/cluster-health.html>`_.

* ``elasticsearch_cluster_active_primary_shards``, the number of active primary
  shards.
* ``elasticsearch_cluster_active_shards``, the number of active shards.
* ``elasticsearch_cluster_health``, the health status of the entire cluster
  where values ``1``, ``2`` , ``3`` represent ``green``, ``yellow`` and
  ``red``, respectively. The ``red`` status may also be reported when the
  Elasticsearch API returns an unexpected result,  for example, a network
  failure.
* ``elasticsearch_cluster_initializing_shards``, the number of initializing
  shards.
* ``elasticsearch_cluster_number_of_nodes``, the number of nodes in the cluster.
* ``elasticsearch_cluster_number_of_pending_tasks``, the number of pending tasks.
* ``elasticsearch_cluster_relocating_shards``, the number of relocating shards.
* ``elasticsearch_cluster_unassigned_shards``, the number of unassigned shards.