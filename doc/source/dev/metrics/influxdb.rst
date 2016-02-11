.. InfluxDB:

The following metrics are extracted from the output of ``show stats`` command.
The values are reset to zero when InfluxDB is restarted.

cluster
^^^^^^^

These metrics are only available if there are more than one node in the cluster.

* ``influxdb_cluster_write_shard_points_requests``, the number of requests for writing a time series points to a shard.
* ``influxdb_cluster_write_shard_requests``, the number of requests for writing to a shard.

httpd
^^^^^

* ``influxdb_httpd_health``, the health status reported when the InfluxDB API returns
  either a valid response or an unexpected result (network failure for instance)
  where the metric's value is respectively ``1`` for ``OKAY`` and ``3`` for ``DOWN``.
* ``influxdb_httpd_failed_auths``, the number of times failed authentications.
* ``influxdb_httpd_ping_requests``, the number of ping requests.
* ``influxdb_httpd_write_points_ok``, the number of points successfully written.
* ``influxdb_httpd_query_requests``, the number of query requests received.
* ``influxdb_httpd_query_response_bytes``, the number of bytes returned to the client.
* ``influxdb_httpd_requests``, the number of requests received.
* ``influxdb_httpd_write_requests``, the number of write requests received.
* ``influxdb_httpd_write_request_bytes``, the number of bytes received for write requests.

write
^^^^^

* ``influxdb_write_point_requests``, the number of write points requests across all data nodes.
* ``influxdb_write_local_point_requests``, the number of write points requests from the local data node.
* ``influxdb_write_remote_point_requests``, the number of write points requests to remote data nodes.
* ``influxdb_write_requests``, the number of write requests across all data nodes.
* ``influxdb_write_sub_ok``, the number of successful points send to subscriptions.
* ``influxdb_write_ok``, the number of successful writes of consistency level.

runtime
^^^^^^^

* ``influxdb_memory_alloc``, the number of bytes allocated and not yet freed.
* ``influxdb_memory_total_alloc``, the number of bytes allocated (even if freed).
* ``influxdb_memory_system``, the number of bytes obtained from the system.
* ``influxdb_memory_lookups``, the number of pointer lookups.
* ``influxdb_memory_mallocs``, the number of malloc operations.
* ``influxdb_memory_frees``, the number of free operations.
* ``influxdb_heap_idle``, the number of bytes in idle spans.
* ``influxdb_heap_in_use``, the number of bytes in non-idle spans.
* ``influxdb_heap_objects``, the total number of allocated objects.
* ``influxdb_heap_released``, the number of bytes released to the operating system.
* ``influxdb_heap_system``, the number of bytes obtained from the system.
* ``influxdb_garbage_collections``, the number of garbage collections.
* ``influxdb_go_routines``, the number of Golang routines.
