.. _Ceph_metrics:


All metrics are prefixed by ``ceph.cluster-<name>`` with ``<name>`` is *ceph*
by default.

Cluster
^^^^^^^

* ``health``, the health status of the entire cluster where values ``1``, ``2``
  , ``3`` represent respectively ``OK``, ``WARNING`` and ``ERROR``.

* ``monitor``, number of ceph-mon process.
* ``quorum``, number of quorum members.

Pools
^^^^^

* ``pool.<name>.bytes_used``, number of bytes used per pool.
* ``pool.<name>.max_avail``, number of bytes available per pool.
* ``pool.<name>.objects``, number of objects per pool.
* ``pool.<name>.read_bytes_sec``, number of bytes by second read per pool.
* ``pool.<name>.write_bytes_sec``, number of bytes by second write per pool.
* ``pool.<name>.op_per_sec``, number of operations per second per pool.
* ``pool.<name>.size``, number of data replication per pool.
* ``pool.<name>.pg_num``, number of Placement Group per pool.
* ``pool.total_bytes``,  total bytes available for all pools.
* ``pool.total_used_bytes``, total bytes used by all pools.
* ``pool.total_avail_bytes``, total byte available for all pools.
* ``pool.total_number``, total number of pool.

With ``<name>`` the name of the pool.

Placement Group
^^^^^^^^^^^^^^^

* ``pg.number``, total number of Placement Group.
* ``pg.state.<state>``, number of Placement Group by state.
* ``pg.bytes_avail``, number of bytes available.
* ``pg.bytes_total``, number total of bytes.
* ``pg.bytes_used``, number of bytes used
* ``pg.data_bytes``, number of bytes used for ????.

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
* ``osd.<num>.used``, bytes used per OSD daemon.
* ``osd.<num>.total``, total bytes per OSD daemon.
* ``osd.<num>.apply_latency``, apply latency per OSD daemon.
* ``osd.<num>.commit_latency``, commit latency per OSD daemon.

With ``<num>`` the OSD numeric ID.

OSD Performance
^^^^^^^^^^^^^^^

TODO
