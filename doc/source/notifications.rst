.. _notifications:

=====================
Notification Messages
=====================

OpenStack services can be configured to send notifications on the message bus
about the executing task or the state of the cloud resources [#]_. These
notifications are received by the LMA collector service and turned into Heka
messages.

Notification Messages Format
============================

In addition to the common :ref:`message_format`, notification-based messages
have additional properties.

Attributes in **bold** are always present in the messages while attributes in
*italic* are optional.

* **Logger** (string), the OpenStack service that emitted the notification,
  (eg, ``nova``).

* **Payload** (string), the payload of the OpenStack notification.

* **Hostname** (string), the name of the host that originated the notification.

* **Type** (string), always ``notification``.

* **Fields**

  * **hostname** (string), the name of the host that originated the
    notification.

  * **publisher** (string), the name of the underlying service that emitted the
    notification (eg, ``scheduler``).

  * **severity_label** (string), the textual representation of the severity
    level.

  * **event_type** (string), the notification's type (eg
    ``compute.instance.create.end``).

  * *tenant_id* (string), the UUID of the OpenStack tenant to which the message
    applies.

  * *user_id* (string), the UUID of the OpenStack user to which the message
    applies.

  * *instance_id* (string), the UUID of the virtual instance to which the
    message applies.

  * *image_name* (string), the image used by the image.

  * *display_name* (string), the visible name of the resource.

  * *instance_type* (string), the type of instance (eg ``m1.small``).

  * *availability_zone* (string), the availability zone of the instance.

  * *vcpus* (number), the number of VCPU provisioned for the instance.

  * *memory_mb* (number), the amount of RAM provisioned for the instance.

  * *disk_gb* (number), the disk space provisioned for the instance.

  * *old_state* (string), the previous state of the instance (eg ``building``).

  * *state* (string), the state of the instance (eg ``active``).

  * *old_task_state* (string), the previous task state for the instance (eg
    ``block_device_mapping``).

  * *new_task_state* (string), the new task state for the instance (eg
    ``spawning``).

  * *created_at* (string): the date of creation of the instance.

  * *launched_at* (string): the date when the instance was effectively
    launched.

  * *deleted_at* (string): the date of deletion of the instance.

  * *terminated_at* (string): the date when the instance was effectively
    terminated.

.. [#]
   `OpenStack notifications <http://docs.openstack.org/admin-guide-cloud/content/section_telemetry-notifications.html>`_
