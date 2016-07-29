.. _heartbeat_metrics:

The heartbeat metrics are emitted to express the success or the failure of the
metric collections for the local services.
The value is ``1`` when successful and ``0`` if it fails.

* ``rabbitmq_heartbeat``, for RabbitMQ.
* ``haproxy_heartbeat``, for HAProxy.
* ``ceph_heartbeat``, for Ceph.
* ``pacemaker_heartbeat``, for Pacemaker.
* ``elasticsearch_heartbeat``, for Elasticsearch.
