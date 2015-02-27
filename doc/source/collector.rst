.. _collector_service:


=================
Collector service
=================

The collector service leverages:

* `collectd <http://www.collectd.org/>`_ for gathering system and operational :ref:`metrics` which are then
  sent to Heka.

* `Heka <http://hekad.readthedocs.org/en/latest/index.html>`_ for parsing
  :ref:`logs`, collecting OpenStack :ref:`notifications` and receiving metrics
  from collectd.

.. _message_format:

Message format
==============

Heka turns the incoming data into Heka messages [#]_ with a well-defined format
which is described below.

* **Timestamp** (number), the timestamp of the message (in nanoseconds since the
  Epoch).

* **Logger** (string), the datasource from the Heka's standpoint.

* **Type** (string), the type of message.

* **Hostname** (string), the name of the host that emitted the message.

* **Severity** (number), severity level as defined by the Syslog `RFC
  5424 <https://tools.ietf.org/html/rfc5424>`_.

* **Payload** (string), the input data in most cases.

* **Pid** (number), the Process ID that generated the message.

* **Fields**, array of Field structures (see below).

Field format
============

Every message (either originating from logs, metrics or notifications) is
populated with a set of predefined fields:

* **deployment_mode** (string), the deployment of the Fuel environment (either
  'multinode' or 'ha_compact').

* **fuel_environment** (string), the name of the Fuel environment.

* **os_region** (string), the name of the OpenStack region.

* **os_release** (string), the name of the OpenStack release.

* **os_roles** (string), a comma-separated list of the node's roles (eg
  'controller', 'compute,storage').

.. note:: All date/time fields represented as string are formatted according
   to the `RFC3339 <http://tools.ietf.org/html/rfc3339>`_ document.

.. [#] `Heka message structure <http://hekad.readthedocs.org/en/latest/message/index.html>`_
