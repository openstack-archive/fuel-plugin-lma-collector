.. _logs:

============
Log Messages
============

The Heka collector service is configured to tail the following log files:

* System logs.

  * ``/var/log/auth.log``
  * ``/var/log/cron.log``
  * ``/var/log/daemon.log``
  * ``/var/log/kern.log``

* MySQL server logs (for controller nodes).

* RabbitMQ server logs (for controller nodes).

* Pacemaker logs (for controller nodes).

* OpenStack logs.

Log Messages Format
===================

In addition to the common :ref:`message_format`, log-based messages have
additional properties.

Attributes in **bold** are always present in the messages while attributes in
*italic* are optional.

* **Logger** (string), ``system.<service>``, ``mysql`` or
  ``openstack.<service>``.

* **Type** (string), always ``log``.

* **Fields**

  * **severity_label** (string), the textual representation of the severity
    level.

  * *programname* (string), the application name for Syslog-based messages.

  * *syslogfacility* (number), the Syslog facility for Syslog-based messages.

  * *request_id* (string), the UUID of the OpenStack request.
    applies.

  * *tenant_id* (string), the UUID of the OpenStack tenant to which the message
    applies.

  * *user_id* (string), the UUID of the OpenStack user to which the message
    applies.
