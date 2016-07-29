.. _check-metrics:

The check metrics are emitted to express the success or the failure of the
metric collections for the local services.
The value is ``1`` when successful and ``0`` if it fails.

* ``rabbitmq_check``, for RabbitMQ.
* ``haproxy_check``, for HAProxy.
* ``pacemaker_check``, for Pacemaker.
* ``ceph_mon_check``, for Ceph monitor.
* ``ceph_osd_check``, for Ceph OSD.
* ``elasticsearch_check``, for Elasticsearch.
* ``influxdb_check``, for InfluxDB.
