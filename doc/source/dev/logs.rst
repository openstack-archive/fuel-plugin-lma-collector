.. _logs:

============
Log Messages
============

The Heka collector service is configured to tail the following log files:

* System logs.

  * ``/var/log/syslog``
  * ``/var/log/messages``
  * ``/var/log/debug``
  * ``/var/log/auth.log``
  * ``/var/log/cron.log``
  * ``/var/log/daemon.log``
  * ``/var/log/kern.log``
  * ``/var/log/pacemaker.log``

* MySQL server logs (for controller nodes).

* RabbitMQ server logs (for controller nodes).

* Pacemaker logs (for controller nodes).

* OpenStack logs.

* Open vSwitch logs (all nodes).

  * ``/var/log/openvswitch/ovsdb-server.log``
  * ``/var/log/openvswitch/ovs-vswitchd.log``

Log Messages Format
===================

In addition to the common :ref:`common_message_format`, log-based messages have
additional properties.

Attributes in **bold** are always present in the messages while attributes in
*italic* are optional.

* **Logger** (string), ``system.<service>``, ``mysql`` or
  ``openstack.<service>``.

* **Type** (string), always ``log``.

* **Fields**

  * **severity_label** (string), the textual representation of the severity
    level.

  * *programname* (string), the application name for Syslog-based messages, or
    the OpenStack service daemon name for OpenStack log messages (eg
    "nova-compute").

  * *syslogfacility* (number), the Syslog facility for Syslog-based messages.

  * *http_method* (string), the HTTP method (for instance 'GET').

  * *http_client_ip_address* (string), the IP address of the client that
    originated the HTTP request.

  * *http_response_size* (number), the size of the HTTP response (in bytes).

  * *http_response_time* (number), the HTTP response time (in seconds).

  * *http_status* (string), the HTTP response status.

  * *http_url* (string), the requested HTTP URL.

  * *http_version* (string), the HTTP version (eg '1.1).

  * *request_id* (string), the UUID of the OpenStack request to which the
    message applies.

  * *tenant_id* (string), the UUID of the OpenStack tenant to which the message
    applies.

  * *user_id* (string), the UUID of the OpenStack user to which the message
    applies.
