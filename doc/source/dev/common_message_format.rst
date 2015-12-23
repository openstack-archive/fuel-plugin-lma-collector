.. _common_message_format:

=====================
Common Message Format
=====================

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

Field Format
============

Every message (either originating from logs, metrics or notifications) is
populated with a set of predefined fields:

Attributes in **bold** are always present in the messages while attributes in
*italic* are optional.

* **deployment_id** (number), the deployment identifier of the Fuel
  environment.

* **openstack_region** (string), the name of the OpenStack region.

* **openstack_release** (string), the name of the OpenStack release.

* **openstack_roles** (string), a comma-separated list of the node's roles (eg
  'controller', 'compute,cinder').

* *environment_label* (string), the label assigned to the OpenStack
  environment.

.. note:: All date/time fields represented as string are formatted according
   to the `RFC3339 <http://tools.ietf.org/html/rfc3339>`_ document.

.. [#] `Heka message structure <http://hekad.readthedocs.org/en/latest/message/index.html>`_
