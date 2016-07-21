.. _Ceph_metrics:


All Ceph metrics have a ``cluster`` field containing the name of the Ceph
cluster (*ceph* by default).

For details, see
`Cluster monitoring <http://docs.ceph.com/docs/master/rados/operations/monitoring/>`_
and `RADOS monitoring <http://docs.ceph.com/docs/master/rados/operations/monitoring-osd-pg/>`_.

Cluster
^^^^^^^

* ``ceph_health``, the health status of the entire cluster where values
  ``1``, ``2``, ``3`` represent  ``OK``, ``WARNING`` and ``ERROR``, respectively.

* ``ceph_monitor_count``, the number of ceph-mon processes.

* ``ceph_quorum_count``, the number of ceph-mon processes participating in the
  quorum.

Pools
^^^^^

* ``ceph_pool_total_avail_bytes``, the total available size in bytes for all
  pools.
* ``ceph_pool_total_bytes``, the total number of bytes for all pools.
* ``ceph_pool_total_number``, the total number of pools.
* ``ceph_pool_total_used_bytes``, the total used size in bytes by all pools.

The following metrics have a ``pool`` field that contains the name of the
Ceph pool.

* ``ceph_pool_bytes_used``, the amount of data in bytes used by the pool.
* ``ceph_pool_max_avail``, the available size in bytes for the pool.
* ``ceph_pool_objects``, the number of objects in the pool.
* ``ceph_pool_op_per_sec``, the number of operations per second for the pool.
* ``ceph_pool_pg_num``, the number of placement groups for the pool.
* ``ceph_pool_read_bytes_sec``, the number of bytes read by second for the pool.
* ``ceph_pool_size``, the number of data replications for the pool.
* ``ceph_pool_write_bytes_sec``, the number of bytes written by second for the
  pool.

Placement Groups
^^^^^^^^^^^^^^^^

* ``ceph_pg_bytes_avail``, the available size in bytes.
* ``ceph_pg_bytes_total``, the cluster total size in bytes.
* ``ceph_pg_bytes_used``, the data stored size in bytes.
* ``ceph_pg_data_bytes``, the stored data size in bytes before it is
  replicated, cloned or snapshotted.
* ``ceph_pg_state``, the number of placement groups in a given state. The
  metric contains a ``state`` field whose ``<state>`` value is a combination
  separated by ``+`` of 2 or more states of this list: ``creating``,
  ``active``, ``clean``, ``down``, ``replay``, ``splitting``, ``scrubbing``,
  ``degraded``, ``inconsistent``, ``peering``, ``repair``, ``recovering``,
  ``recovery_wait``, ``backfill``, ``backfill-wait``, ``backfill_toofull``,
  ``incomplete``, ``stale``, ``remapped``.
* ``ceph_pg_total``, the total number of placement groups.

OSD Daemons
^^^^^^^^^^^

* ``ceph_osd_down``, the number of OSD daemons DOWN.
* ``ceph_osd_in``, the number of OSD daemons IN.
* ``ceph_osd_out``, the number of OSD daemons OUT.
* ``ceph_osd_up``, the number of OSD daemons UP.

The following metrics have an ``osd`` field that contains the OSD identifier:

* ``ceph_osd_apply_latency``, apply latency in ms for the given OSD.
* ``ceph_osd_commit_latency``, commit latency in ms for the given OSD.
* ``ceph_osd_total``, the total size in bytes for the given OSD.
* ``ceph_osd_used``, the data stored size in bytes for the given OSD.

OSD Performance
^^^^^^^^^^^^^^^

All the following metrics are retrieved per OSD daemon from the corresponding
``/var/run/ceph/ceph-osd.<ID>.asok`` socket by issuing the :command:`perf dump`
command.

All metrics have an ``osd`` field that contains the OSD identifier.

.. note:: These metrics are not collected when a node has both the ceph-osd
   and controller roles.

For details, see `OSD performance counters <http://ceph.com/docs/firefly/dev/perf_counters/>`_.

* ``ceph_perf_osd_op``, the number of client operations.
* ``ceph_perf_osd_op_in_bytes``, the number of bytes received from clients for
  write operations.
* ``ceph_perf_osd_op_latency``, the average latency in ms for client operations
  (including queue time).
* ``ceph_perf_osd_op_out_bytes``, the number of bytes sent to clients for read
  operations.
* ``ceph_perf_osd_op_process_latency``, the average latency in ms for client
  operations (excluding queue time).
* ``ceph_perf_osd_op_r``, the number of client read operations.
* ``ceph_perf_osd_op_r_latency``, the average latency in ms for read operation
  (including queue time).
* ``ceph_perf_osd_op_r_out_bytes``, the number of bytes sent to clients for
  read operations.
* ``ceph_perf_osd_op_r_process_latency``, the average latency in ms for read
  operation (excluding queue time).
* ``ceph_perf_osd_op_rw``, the number of client read-modify-write operations.
* ``ceph_perf_osd_op_rw_in_bytes``, the number of bytes per second received
  from clients for read-modify-write operations.
* ``ceph_perf_osd_op_rw_latency``, the average latency in ms for
  read-modify-write operations (including queue time).
* ``ceph_perf_osd_op_rw_out_bytes``, the number of bytes per second sent to
  clients for read-modify-write operations.
* ``ceph_perf_osd_op_rw_process_latency``, the average latency in ms for
  read-modify-write operations (excluding queue time).
* ``ceph_perf_osd_op_rw_rlat``, the average latency in ms for read-modify-write
  operations with readable/applied.
* ``ceph_perf_osd_op_w``, the number of client write operations.
* ``ceph_perf_osd_op_wip``, the number of replication operations currently
  being processed (primary).
* ``ceph_perf_osd_op_w_in_bytes``, the number of bytes received from clients
  for write operations.
* ``ceph_perf_osd_op_w_latency``, the average latency in ms for write
  operations (including queue time).
* ``ceph_perf_osd_op_w_process_latency``, the average latency in ms for write
  operation (excluding queue time).
* ``ceph_perf_osd_op_w_rlat``, the average latency in ms for write operations
  with readable/applied.
* ``ceph_perf_osd_recovery_ops``, the number of recovery operations in progress.