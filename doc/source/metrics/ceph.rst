.. _Ceph_metrics:


All metrics are prefixed by ``ceph.cluster-<name>`` with ``<name>`` is *ceph*
by default.

See `cluster monitoring`_ and `rados monitoring`_ for further details.

Cluster
^^^^^^^

* ``health``, the health status of the entire cluster where values ``1``, ``2``
  , ``3`` represent respectively ``OK``, ``WARNING`` and ``ERROR``.

* ``monitor``, number of ceph-mon process.
* ``quorum``, number of quorum members.

Pools
^^^^^

* ``pool.<name>.bytes_used``, data stored size in bytes per pool.
* ``pool.<name>.max_avail``, available size in bytes per pool.
* ``pool.<name>.objects``, number of objects per pool.
* ``pool.<name>.read_bytes_sec``, number of bytes read by second per pool.
* ``pool.<name>.write_bytes_sec``, number of bytes written by second per pool.
* ``pool.<name>.op_per_sec``, number of operations per second per pool.
* ``pool.<name>.size``, number of data replication per pool.
* ``pool.<name>.pg_num``, number of placement group per pool.
* ``pool.total_bytes``,  total number of bytes for all pools.
* ``pool.total_used_bytes``, total used size in bytes by all pools.
* ``pool.total_avail_bytes``, total available size in bytes for all pools.
* ``pool.total_number``, total number of pools.

``<name>`` is the name of the Ceph pool.

Placement Groups
^^^^^^^^^^^^^^^^

* ``pg.number``, total number of placement group.
* ``pg.state.<state>``, number of placement group by state.
* ``pg.bytes_avail``, available size in bytes.
* ``pg.bytes_total``, cluster total size in bytes.
* ``pg.bytes_used``, data stored size in bytes.
* ``pg.data_bytes``, stored data size in bytes before it is replicated, cloned
  or snapshotted.

``<state>`` is a combination separated by ``+`` of 2 or more states of this
list: ``creating``, ``active``, ``clean``, ``down``, ``replay``, ``splitting``,
``scrubbing``, ``degraded``, ``inconsistent``, ``peering``, ``repair``,
``recovering``, ``recovery_wait``, ``backfill``, ``backfill-wait``,
``backfill_toofull``, ``incomplete``, ``stale``, ``remapped``,

OSD Daemons
^^^^^^^^^^^

* ``osd.up``, number of OSD daemons UP.
* ``osd.down``, number of OSD daemons DOWN.
* ``osd.in``, number of OSD daemons IN.
* ``osd.out``, number of OSD daemons OUT.
* ``osd.<id>.used``, data stored size in bytes.
* ``osd.<id>.total``, total size in bytes.
* ``osd.<id>.apply_latency``, apply latency.
* ``osd.<id>.commit_latency``, commit latency.

``<id>`` is the OSD numeric ID.

OSD Performance
^^^^^^^^^^^^^^^

All the following metrics are retrieved per OSD daemon from the corresponding
socket ``/var/run/ceph/ceph-osd.<ID>.asok`` by issuing the command ``perf dump``.

See `OSD perf counters`_ for further details.

* ``osd-<id>.objecter.osd_sessions``, number of open sessions.
* ``osd-<id>.objecter.osd_session_open``, number of created sessions.
* ``osd-<id>.objecter.osd_session_close``, number of removed sessions.
* ``osd-<id>.objecter.op_commit``, number of commits.
* ``osd-<id>.osd.recovery_ops``, number of started recovery operations.
* ``osd-<id>.osd.op_wip``, replication operations currently being processed (primary).
* ``osd-<id>.osd.op``, client operations.
* ``osd-<id>.osd.op_in_bytes``, client operations total write size.
* ``osd-<id>.osd.op_out_bytes``, client operations total read size.
* ``osd-<id>.osd.op_latency``, latency in ms of client operations (including queue time).
* ``osd-<id>.osd.op_process_latency``, latency in ms of client operations (excluding queue time).
* ``osd-<id>.osd.op_r``, number of client read operations.
* ``osd-<id>.osd.op_r_out_bytes``, client data read.
* ``osd-<id>.osd.op_r_latency``, latency in ms of read operation (including queue time).
* ``osd-<id>.osd.op_r_process_latency``, latency in ms of read operation (excluding queue time).
* ``osd-<id>.osd.op_w``, number of client write operations.
* ``osd-<id>.osd.op_w_in_bytes``, client data written.
* ``osd-<id>.osd.op_w_rlat``, client write operation readable/applied latency.
* ``osd-<id>.osd.op_w_latency``, latency in ms of write operation (including queue time).
* ``osd-<id>.osd.op_w_process_latency``, latency of write operation (excluding queue time).
* ``osd-<id>.osd.op_rw``, number of Client read-modify-write operations.
* ``osd-<id>.osd.op_rw_in_bytes``, client read-modify-write operations write in.
* ``osd-<id>.osd.op_rw_out_bytes``, client read-modify-write operations read out.
* ``osd-<id>.osd.op_rw_rlat``, client read-modify-write operation readable/applied latency.
* ``osd-<id>.osd.op_rw_latency``, latency in ms of read-modify-write operation (including queue time).
* ``osd-<id>.osd.op_rw_process_latency``, latency in ms of read-modify-write operation (excluding queue time).

With ``<id>`` is the OSD numeric identifier.

.. _cluster monitoring: http://docs.ceph.com/docs/master/rados/operations/monitoring/
.. _rados monitoring: http://docs.ceph.com/docs/master/rados/operations/monitoring-osd-pg/
.. _OSD perf counters: http://ceph.com/docs/firefly/dev/perf_counters/
