.. _metrics:

================
Metric Messages
================

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

* **Type** (string), either ``metric`` or ``heka.sandbox.metric`` (for metrics
  derived from other messages).

* **Severity** (number), it is always equal to 6 (eg INFO).

* **Fields**

 * **name** (string), the name of the metric. See :ref:`metric_list` for the
   current metrics names that are emitted.

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

 * *device* (string), the name of the physical device. For instance ``sda`` or
   ``eth0``.

 * *interval* (number), the interval at which the metric is emitted (for
   ``collectd`` metrics).

 * *tenant_id* (string), the UUID of the OpenStack tenant to which the metric
   applies.

 * *user_id* (string), the UUID of the OpenStack user to which the metric
   applies.

.. _metric_list:

List of metrics
===============

This is the list of metrics that are emitted by the LMA collector service. They
are listed by category then by metric name.

System
------

.. include:: metrics/system.rst

MySQL
-----

.. include:: metrics/mysql.rst

RabbitMQ
--------

.. include:: metrics/rabbitmq.rst

OpenStack
---------

.. include:: metrics/openstack.rst
