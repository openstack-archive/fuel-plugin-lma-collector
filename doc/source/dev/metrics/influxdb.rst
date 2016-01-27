.. InfluxDB:

The following metrics are extracted from the output of 'show stats' command.
Values are stored in memory so they are reset to zero when InfluxDB is
restarted.

cluster
^^^^^^^

* ``cluster_write_shard_points_request``, the number of requests for writing a time series points to a shard.
* ``cluster_write_shard_request``, the number of requests for writing to a shard.

httpd
^^^^^

* ``httpd_auth_failed``, the number of times the authentication failed.
* ``httpd_ping_request``, the number of ping requests.
* ``httpd_points_written_ok``, the number of points successfully written.
* ``httpd_query_request``, the number of queries received.
* ``httpd_query_respond_bytes``, the number of bytes returned to the client.
* ``httpd_request``, the number of request received.
* ``httpd_write_request``, the number of write received.
* ``httpd_write_request_bytes``, the number of write received in bytes.

write
^^^^^

* ``write_point_request``, the number of write points requests across multiple data nodes.
* ``write_point_request_local``, the number of write points requests from local data nodes.
* ``write_point_req_remote``, the number of write points requests across remote data node.
* ``write_request``, the number of write requests across multiple data nodes.
* ``write_sub_write_ok``, the number of successful points send to subscriptions.
* ``write_ok``, the number of successful writes of consistency level.

runtime
^^^^^^^

* ``runtime_alloc``, the number of bytes allocated and not yet freed.
* ``runtime_total_alloc``, the number of bytes allocated (even if freed)
* ``runtime_system``, the number of bytes obtained from system.
* ``runtime_lookups``, the number of pointer lookups.
* ``runtime_mallocs``, the number of malloc.
* ``runtime_frees``, the number of frees.
* ``runtime_heap_alloc``, the number of bytes allocated and not yet freed (same as alloc).
* ``runtime_heap_idle``, the number of bytes in idle spans.
* ``runtime_heap_in_use``, the number of bytes in non-idle spans.
* ``runtime_heap_released``, the number of bytes released to the OS.
* ``runtime_heap_objects``, the total number of allocated objects.
* ``runtime_heap_system``, the number of bytes obtained from system.
* ``runtime_num_garbage_collector``, the number of garbage collector
* ``runtime_num_go_routine``, the number of go routine
* ``runtime_pause_total``, the total number of garbage collector pause durations.
