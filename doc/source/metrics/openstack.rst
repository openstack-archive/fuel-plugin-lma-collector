.. _openstack_metrics:

Service checks
^^^^^^^^^^^^^^

* ``openstack.<service>.check_api``, the service's API status, 1 if it is responsive, 0 otherwise.

``<service>`` is one of 'cinder', 'glance', 'heat' 'keystone', 'neutron' or 'nova'.

Compute
^^^^^^^

These metrics are emitted per compute node.

* ``openstack.nova.instance_creation_time``, the time (in seconds) it took to launch a new instance.
* ``openstack.nova.instance_state.<state>``, the number of instances which entered this state (always 1).
* ``openstack.nova.free_disk``, the amount of disk space (in GB) available for new instances.
* ``openstack.nova.used_disk``, the amount of disk space (in GB) used by the instances.
* ``openstack.nova.free_ram``, the amount of memory (in MB) available for new instances.
* ``openstack.nova.used_ram``, the amount of memory (in MB) used by the instances.
* ``openstack.nova.free_vcpus``, the number of virtual CPU available for new instances.
* ``openstack.nova.used_vcpus``, the number of virtual CPU used by the instances.
* ``openstack.nova.running_instances``, the number of running instances on the node.
* ``openstack.nova.running_tasks``, the number of tasks currently executed by the node.

These metrics are retrieved from the Nova API

* ``openstack.nova.servers.<state>``, the number of instances by state.
* ``openstack.nova.services.<service>.enable``, the number of enabled Nova
  services by service name.
* ``openstack.nova.services.<service>.disable``, the number of disabled Nova
  services by service name.

``<state>`` is one of 'active', 'deleted', 'error', 'paused', 'resumed', 'rescued', 'resized', 'shelved_offloaded' or 'suspended'.

``<service>`` is one of service is one of 'compute', 'conductor', 'scheduler', 'cert' or 'consoleauth'.

Volume
^^^^^^

These metrics are retrieved from the Cinder API

* ``openstack.cinder.volumes.<state>``, the number of volumes by state.
* ``openstack.cinder.snapshots.<state>``, the number of snapshots by state.
* ``openstack.cinder.size.volumes.usable``, the total size of usable volumes (not in error)
* ``openstack.cinder.size.volumes.in_error``, the total size of volumes in error

``<state>`` is one of 'available', 'creating', 'attaching', 'in-use', 'deleting', 'backing-up', 'restoring-backup', 'error', 'error_deleting', 'error_restoring', 'error_extending'

Image
^^^^^

These metrics are retrieved from the Glance API

* ``openstack.glance.images.public.<state>``, the number of public images by state.
* ``openstack.glance.images.private.<state>``, the number of private images by state.
* ``openstack.glance.snapshots.public.<state>``, the number of public snapshot images by state.
* ``openstack.glance.snapshots.private.<state>``, the number of private snapshot images by state.
* ``openstack.glance.images.size.active``, the total size (in GB) of active images.
* ``openstack.glance.images.size.other``, the total size (in GB) of images in other state.
* ``openstack.glance.snapshots.size.active``, the total size (in GB) of active snapshots.
* ``openstack.glance.snapshots.size.other``, the total size (in GB) of snapshots in other state.

``<state>`` is one of 'queued', 'saving', 'active', 'killed', 'deleted', 'pending_delete'.

API response times
^^^^^^^^^^^^^^^^^^

* ``openstack.<service>.http.<HTTP method>.<HTTP status>``, the time (in second) it took to serve the HTTP request.

``<service>`` is one of 'cinder', 'glance', 'heat' 'keystone', 'neutron' or 'nova'.
``<HTTP method>`` is the HTTP method name, eg 'GET', 'POST' and so on.
``<HTTP status>`` is a 3-digit string representing the HTTP response code, eg '200', '404' and so on.
