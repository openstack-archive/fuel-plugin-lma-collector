.. _Ceph_metrics:


All Ceph metrics have a ``cluster`` field containing the name of the Ceph cluster
(*ceph* by default).

See `cluster monitoring`_ and `RADOS monitoring`_ for further details.

Cluster
^^^^^^^

* ``ceph_health``, the health status of the entire cluster where values ``1``, ``2``
  , ``3`` represent respectively ``OK``, ``WARNING`` and ``ERROR``.

* ``ceph_monitor_count``, number of ceph-mon processes.

* ``ceph_quorum_count``, number of ceph-mon processes participating in the
  quorum.

Pools
^^^^^

* ``ceph_pool_total_bytes``,  total number of bytes for all pools.
* ``ceph_pool_total_used_bytes``, total used size in bytes by all pools.
* ``ceph_pool_total_avail_bytes``, total available size in bytes for all pools.
* ``ceph_pool_total_number``, total number of pools.

The folllowing metrics have a ``pool`` field that contains the name of the Ceph pool.

* ``ceph_pool_bytes_used``, amount of data in bytes used by the pool.
* ``ceph_pool_max_avail``, available size in bytes for the pool.
* ``ceph_pool_objects``, number of objects in the pool.
* ``ceph_pool_read_bytes_sec``, number of bytes read by second for the pool.
* ``ceph_pool_write_bytes_sec``, number of bytes written by second for the pool.
* ``ceph_pool_op_per_sec``, number of operations per second for the pool.
* ``ceph_pool_size``, number of data replications for the pool.
* ``ceph_pool_pg_num``, number of placement groups for the pool.

Placement Groups
^^^^^^^^^^^^^^^^

* ``ceph_pg_total``, total number of placement groups.
* ``ceph_pg_bytes_avail``, available size in bytes.
* ``ceph_pg_bytes_total``, cluster total size in bytes.
* ``ceph_pg_bytes_used``, data stored size in bytes.
* ``ceph_pg_data_bytes``, stored data size in bytes before it is replicated, cloned
  or snapshotted.
* ``ceph_pg_state``, number of placement groups in a given state. The metric
  contains a ``state`` field whose value is ``<state>`` is a combination
  separated by ``+`` of 2 or more states of this list: ``creating``,
  ``active``, ``clean``, ``down``, ``replay``, ``splitting``, ``scrubbing``,
  ``degraded``, ``inconsistent``, ``peering``, ``repair``, ``recovering``,
  ``recovery_wait``, ``backfill``, ``backfill-wait``, ``backfill_toofull``,
  ``incomplete``, ``stale``, ``remapped``.

OSD Daemons
^^^^^^^^^^^

* ``ceph_osd_up``, number of OSD daemons UP.
* ``ceph_osd_down``, number of OSD daemons DOWN.
* ``ceph_osd_in``, number of OSD daemons IN.
* ``ceph_osd_out``, number of OSD daemons OUT.

The following metrics have an ``osd`` field that contains the OSD identifier.

* ``ceph_osd_used``, data stored size in bytes for the given OSD.
* ``ceph_osd_total``, total size in bytes for the given OSD.
* ``ceph_osd_apply_latency``, apply latency in ms for the given OSD.
* ``ceph_osd_commit_latency``, commit latency in ms for the given OSD.

OSD Performance
^^^^^^^^^^^^^^^

All the following metrics are retrieved per OSD daemon from the corresponding
socket ``/var/run/ceph/ceph-osd.<ID>.asok`` by issuing the command ``perf dump``.

All metrics have an ``osd`` field that contains the OSD identifier.

.. note:: These metrics are not collected when a node has both the ceph-osd and controller roles.

See `OSD performance counters`_ for further details.

* ``ceph_perf_osd_recovery_ops``, number of recovery operations in progress.
* ``ceph_perf_osd_op_wip``, number of replication operations currently being processed (primary).
* ``ceph_perf_osd_op``, number of client operations.
* ``ceph_perf_osd_op_in_bytes``, number of bytes received from clients for write operations.
* ``ceph_perf_osd_op_out_bytes``, number of bytes sent to clients for read operations.
* ``ceph_perf_osd_op_latency``, average latency in ms for client operations (including queue time).
* ``ceph_perf_osd_op_process_latency``, average latency in ms for client operations (excluding queue time).
* ``ceph_perf_osd_op_r``, number of client read operations.
* ``ceph_perf_osd_op_r_out_bytes``, number of bytes sent to clients for read operations.
* ``ceph_perf_osd_op_r_latency``, average latency in ms for read operation (including queue time).
* ``ceph_perf_osd_op_r_process_latency``, average latency in ms for read operation (excluding queue time).
* ``ceph_perf_osd_op_w``, number of client write operations.
* ``ceph_perf_osd_op_w_in_bytes``, number of bytes received from clients for write operations.
* ``ceph_perf_osd_op_w_rlat``, average latency in ms for write operations with readable/applied.
* ``ceph_perf_osd_op_w_latency``, average latency in ms for write operations (including queue time).
* ``ceph_perf_osd_op_w_process_latency``, average latency in ms for write operation (excluding queue time).
* ``ceph_perf_osd_op_rw``, number of client read-modify-write operations.
* ``ceph_perf_osd_op_rw_in_bytes``, number of bytes per second received from clients for read-modify-write operations.
* ``ceph_perf_osd_op_rw_out_bytes``, number of bytes per second sent to clients for read-modify-write operations.
* ``ceph_perf_osd_op_rw_rlat``, average latency in ms for read-modify-write operations with readable/applied.
* ``ceph_perf_osd_op_rw_latency``, average latency in ms for read-modify-write operations (including queue time).
* ``ceph_perf_osd_op_rw_process_latency``, average latency in ms for read-modify-write operations (excluding queue time).

.. _cluster monitoring: http://docs.ceph.com/docs/master/rados/operations/monitoring/
.. _RADOS monitoring: http://docs.ceph.com/docs/master/rados/operations/monitoring-osd-pg/
.. _OSD performance counters: http://ceph.com/docs/firefly/dev/perf_counters/
