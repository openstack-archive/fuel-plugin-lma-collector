.. _metrics:

===============
Metric Messages
===============

Metrics are extracted from several sources:

* Data received from collectd.

* Log messages processed by the collector service.

* OpenStack notifications processed by the collector service.

Metric Messages Format
======================

In addition to the common :ref:`common_message_format`, metric messages have
additional properties.

Attributes in **bold** are always present in the messages while attributes in
*italic* are optional.

* **Logger** (string), the datasource from the Heka's standpoint, it can be
  ``collectd``, ``notification_processor`` or ``http_log_parser``.

* **Type** (string)

 * ``metric`` or ``heka.sandbox.metric`` for the single-value metrics.

 * ``heka.sandbox.multivalue_metric`` for the multi-valued metrics (eg annotations).

 * ``heka.sandbox.bulk_metric`` for the metrics sent by bulk.

 * ``heka.sandbox.afd_service_metric`` for the AFD service metrics.

 * ``heka.sandbox.afd_node_metric`` for the AFD node metrics.

 * ``heka.sandbox.gse_service_cluster_metric`` for the GSE service cluster metrics.

 * ``heka.sandbox.gse_node_cluster_metric`` for the GSE node cluster metrics.

 * ``heka.sandbox.gse_cluster_metric`` for the GSE global cluster metrics.

* **Severity** (number), it is always equal to 6 (INFO).

* **Fields**

 * **name** (string), the name of the metric. See :ref:`metric_list` for the
   current metric names that are emitted.

 * **value** (number), the value associated to the metric.

 * **type** (string), the metric's type, either ``gauge`` (a value that can go
   up or down), ``counter`` (an always increasing value) or ``derive`` (a
   per-second rate).

 * **source** (string), the source from where the metric comes from, it can be
   the name of the collectd plugin, ``<service>-api`` for HTTP response metrics.

 * **hostname** (string), the name of the host to which the metric applies. It
   may be different from the ``Hostname`` value. For instance when the metric is
   extracted from an OpenStack notification, ``Hostname`` is the host that
   captured the notification and ``Fields[hostname]`` is the host that emitted
   the notification.

 * *interval* (number), the interval at which the metric is emitted (for
   the ``collectd`` metrics).

 * *tenant_id* (string), the UUID of the OpenStack tenant to which the metric
   applies.

 * *user_id* (string), the UUID of the OpenStack user to which the metric
   applies.

Metric messages may include additional fields to specify the scope of the
measurement. When this is the case, these fields are detailed in the list of
metrics presented hereafter.

.. _metric_list:

List of metrics
===============

This is the list of metrics that are emitted by the LMA collector service. They
are listed by category then by metric name.

System
------

.. include:: metrics/system.rst

Apache
------

.. include:: metrics/apache.rst

MySQL
-----

.. include:: metrics/mysql.rst

RabbitMQ
--------

.. include:: metrics/rabbitmq.rst

HAProxy
-------

.. include:: metrics/haproxy.rst

Memcached
---------

.. include:: metrics/memcached.rst

Libvirt
-------

.. include:: metrics/libvirt.rst


OpenStack
---------

.. include:: metrics/openstack.rst


Ceph
----

.. include:: metrics/ceph.rst

Pacemaker
---------

.. include:: metrics/pacemaker.rst

Clusters
--------

.. include:: metrics/clusters.rst

LMA self-monitoring
-------------------

.. include:: metrics/lma.rst


Elasticsearch
-------------

.. include:: metrics/elasticsearch.rst


InfluxDB
--------

.. include:: metrics/influxdb.rst
