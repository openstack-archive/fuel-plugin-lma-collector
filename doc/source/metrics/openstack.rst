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

These metrics are retrieved from the Nova API.

* ``openstack.nova.instances.<state>``, the number of instances by state.

``<state>`` is one of 'active', 'deleted', 'error', 'paused', 'resumed', 'rescued', 'resized', 'shelved_offloaded' or 'suspended'.

These metrics are retrieved from the Nova database.

* ``openstack.nova.services.<service>.<service_state>``, the total number of Nova
    services by state.

``<service>`` is one of service is one of 'compute', 'conductor', 'scheduler', 'cert' or 'consoleauth'.

``<service_state>`` is one of 'up', 'down' or 'disabled'.

.. note:: A service is declared 'down' if heartbeat is not observered since
         ``downtime_factor * report_interval`` seconds,
         with ``report_interval=60`` and ``downtime_factor=2`` per default.
         The ``report_interval`` must match the corresponding configuration in ``nova.conf``.


Identity
^^^^^^^^

These metrics are retrieved from the Keystone API.

* ``openstack.keystone.roles``, the total number of roles.
* ``openstack.keystone.tenants.<state>``, the number of tenants by state.
* ``openstack.keystone.users.<state>``, the number of users by state.

``<state>`` is one of 'disabled' or 'enabled'.

Volume
^^^^^^

These metrics are emitted per volume node.

* ``openstack.cinder.volume_creation_time``, the time (in seconds) it took to create a new volume.

.. note:: When using Ceph as the backend storage for volumes, the ``hostname`` value is always set to ``rbd``.

These metrics are retrieved from the Cinder API.

* ``openstack.cinder.volumes.<state>``, the number of volumes by state.
* ``openstack.cinder.snapshots.<state>``, the number of snapshots by state.
* ``openstack.cinder.volumes_size.<state>``, the total size (in bytes) of volumes by state.
* ``openstack.cinder.snapshots_size.<state>``, the total size (in bytes) of snapshots by state.

``<state>`` is one of 'available', 'creating', 'attaching', 'in-use', 'deleting', 'backing-up', 'restoring-backup', 'error', 'error_deleting', 'error_restoring', 'error_extending'.

Image
^^^^^

These metrics are retrieved from the Glance API.

* ``openstack.glance.images.public.<state>``, the number of public images by state.
* ``openstack.glance.images.private.<state>``, the number of private images by state.
* ``openstack.glance.snapshots.public.<state>``, the number of public snapshot images by state.
* ``openstack.glance.snapshots.private.<state>``, the number of private snapshot images by state.
* ``openstack.glance.images_size.public.<state>``, the total size (in bytes) of public images by state.
* ``openstack.glance.images_size.private.<state>``, the total size (in bytes) of private images by state.
* ``openstack.glance.snapshots_size.public.<state>``, the total size (in bytes) of public snapshots by state.
* ``openstack.glance.snapshots_size.private.<state>``, the total size (in bytes) of private snapshots by state.

``<state>`` is one of 'queued', 'saving', 'active', 'killed', 'deleted', 'pending_delete'.

Network
^^^^^^^

These metrics are retrieved from the Neutron API.

* ``openstack.neutron.agents.<agent_type>.<agent_state>``, the total number of Neutron agents by agent type and state.
* ``openstack.neutron.agents.<agent_state>``, the total number of Neutron agents by state.
* ``openstack.neutron.agents``, the total number of Neutron agents.
* ``openstack.neutron.networks.<state>``, the number of virtual networks by state.
* ``openstack.neutron.networks``, the total number of virtual networks.
* ``openstack.neutron.subnets``, the number of virtual subnets.
* ``openstack.neutron.ports.<owner>.<state>``, the number of virtual ports by owner and state.
* ``openstack.neutron.ports``, the total number of virtual ports.
* ``openstack.neutron.routers.<state>``, the number of virtual routers by state.
* ``openstack.neutron.routers``, the total number of virtual routers.
* ``openstack.neutron.floatingips.free``, the number of floating IP addresses which aren't associated.
* ``openstack.neutron.floatingips.associated``, the number of floating IP addresses which are associated.
* ``openstack.neutron.floatingips``, the total number of floating IP addresses.

``<agent_type>`` is one of 'dhcp', 'l3', 'metadata' or 'open_vswitch'.

``<agent_state>`` is one of 'up', 'down' or 'disabled'.

``<state>`` is one of 'active', 'build', 'down' or 'error'.

``<owner>`` is one of 'compute', 'dhcp', 'floatingip', 'floatingip_agent_gateway', 'router_interface', 'router_gateway', 'router_ha_interface', 'router_interface_distributed' or 'router_centralized_snat'.

API response times
^^^^^^^^^^^^^^^^^^

* ``openstack.<service>.http.<HTTP method>.<HTTP status>``, the time (in second) it took to serve the HTTP request.

``<service>`` is one of 'cinder', 'glance', 'heat' 'keystone', 'neutron' or 'nova'.

``<HTTP method>`` is the HTTP method name, eg 'GET', 'POST' and so on.

``<HTTP status>`` is a 3-digit string representing the HTTP response code, eg '200', '404' and so on.
