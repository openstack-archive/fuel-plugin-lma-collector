.. _openstack_metrics:

Service checks
^^^^^^^^^^^^^^
.. _service_checks:

* ``openstack_check_api``, the service's API status, 1 if it is responsive, if not 0.
    The metric contains a ``service`` field that identifies the OpenStack service being checked.

``<service>`` is one of the following values with their respective resource checks:

* 'nova-api': '/'
* 'cinder-api': '/'
* 'cinder-v2-api': '/'
* 'glance-api': '/'
* 'heat-api': '/'
* 'heat-cfn-api': '/'
* 'keystone-public-api': '/'
* 'neutron-api': '/'
* 'ceilometer-api': '/v2/capabilities'
* 'swift-api': '/healthcheck'
* 'swift-s3-api': '/healthcheck'

.. note:: All checks are performed without authentication except for Ceilometer.

Compute
^^^^^^^

These metrics are emitted per compute node.

* ``openstack_nova_instance_creation_time``, the time (in seconds) it took to launch a new instance.
* ``openstack_nova_instance_state``, the number of instances which entered a given state (the value is always 1).
  The metric contains a ``state`` field.
* ``openstack_nova_free_disk``, the disk space (in GB) available for new instances.
* ``openstack_nova_used_disk``, the disk space (in GB) used by the instances.
* ``openstack_nova_free_ram``, the  memory (in MB) available for new instances.
* ``openstack_nova_used_ram``, the memory (in MB) used by the instances.
* ``openstack_nova_free_vcpus``, the number of virtual CPU available for new instances.
* ``openstack_nova_used_vcpus``, the number of virtual CPU used by the instances.
* ``openstack_nova_running_instances``, the number of running instances.
* ``openstack_nova_running_tasks``, the number of tasks currently executed.

If Nova aggregates are defined then the following metrics are emitted per
aggregate.. These metrics contain a ``aggregate``
field containing the aggregate name and a ``aggregate_id`` field containing the
ID (integer) of the aggregate.

* ``openstack_nova_aggregate_free_disk``, the total amount of disk space (in GB) available in given aggregate for new instances.
* ``openstack_nova_aggregate_used_disk``, the total amount of disk space (in GB) used by the instances in given aggregate.
* ``openstack_nova_aggregate_free_ram``, the total amount of memory (in MB) available in given aggregate for new instances.
* ``openstack_nova_aggregate_used_ram``, the total amount of memory (in MB) used by the instances in given aggregate.
* ``openstack_nova_aggregate_free_vcpus``, the total number of virtual CPU available in given aggregate for new instances.
* ``openstack_nova_aggregate_used_vcpus``, the total number of virtual CPU used by the instances in given aggregate.
* ``openstack_nova_aggregate_running_instances``, the total number of running instances in given aggregate.
* ``openstack_nova_aggregate_running_tasks``, the total number of tasks currently executed in given aggregate.

These metrics are retrieved from the Nova API and represent the aggregated
values across all compute nodes.

* ``openstack_nova_total_free_disk``, the total amount of disk space (in GB) available for new instances.
* ``openstack_nova_total_used_disk``, the total amount of disk space (in GB) used by the instances.
* ``openstack_nova_total_free_ram``, the total amount of memory (in MB) available for new instances.
* ``openstack_nova_total_used_ram``, the total amount of memory (in MB) used by the instances.
* ``openstack_nova_total_free_vcpus``, the total number of virtual CPU available for new instances.
* ``openstack_nova_total_used_vcpus``, the total number of virtual CPU used by the instances.
* ``openstack_nova_total_running_instances``, the total number of running instances.
* ``openstack_nova_total_running_tasks``, the total number of tasks currently executed.

These metrics are retrieved from the Nova API.

* ``openstack_nova_instances``, the total count of instances in a given state.
  The metric contains a ``state`` field which is one of 'active', 'deleted',
  'error', 'paused', 'resumed', 'rescued', 'resized', 'shelved_offloaded' or
  'suspended'.

These metrics are retrieved from the Nova database.

.. _compute-service-state-metrics:

* ``openstack_nova_services``, the total count of Nova
  services by state. The metric contains a ``service`` field (one of 'compute',
  'conductor', 'scheduler', 'cert' or 'consoleauth') and a ``state`` field (one
  of 'up', 'down' or 'disabled').

* ``openstack_nova_service``, the Nova service state (either 0 for 'up', 1 for 'down' or 2 for 'disabled').
  The metric contains a ``service`` field (one of 'compute', 'conductor', 'scheduler', 'cert'
  or 'consoleauth') and a ``state`` field (one of 'up', 'down' or 'disabled').

Identity
^^^^^^^^

These metrics are retrieved from the Keystone API.

* ``openstack_keystone_roles``, the total number of roles.
* ``openstack_keystone_tenants``, the number of tenants by state. The metric
  contains a ``state`` field (either 'enabled' or 'disabled').
* ``openstack_keystone_users``, the number of users by state. The metric
  contains a ``state`` field (either 'enabled' or 'disabled').

Volume
^^^^^^

These metrics are emitted per volume node.

* ``openstack_cinder_volume_creation_time``, the time (in seconds) it took to create a new volume.

.. note:: When using Ceph as the backend storage for volumes, the ``hostname`` value is always set to ``rbd``.

These metrics are retrieved from the Cinder API.

* ``openstack_cinder_volumes``, the number of volumes by state. The metric contains a ``state`` field.
* ``openstack_cinder_snapshots``, the number of snapshots by state. The metric contains a ``state`` field.
* ``openstack_cinder_volumes_size``, the total size (in bytes) of volumes by state. The metric contains a ``state`` field.
* ``openstack_cinder_snapshots_size``, the total size (in bytes) of snapshots by state. The metric contains a ``state`` field.

``state`` is one of 'available', 'creating', 'attaching', 'in-use', 'deleting', 'backing-up', 'restoring-backup', 'error', 'error_deleting', 'error_restoring', 'error_extending'.

These metrics are retrieved from the Cinder database.

.. _volume-service-state-metrics:

* ``openstack_cinder_services``, the total count of Cinder services by state.
  The metric contains a ``service`` field (one of 'volume', 'backup',
  'scheduler') and a ``state`` field (one of 'up', 'down' or 'disabled').

* ``openstack_cinder_service``, the Cinder service state (either 0 for 'up', 1 for 'down' or 2 for 'disabled').
  The metric contains a ``service`` field (one of 'volume', 'backup', 'scheduler'),
  and a ``state`` field (one of 'up', 'down' or 'disabled').

Image
^^^^^

These metrics are retrieved from the Glance API.

* ``openstack_glance_images``, the number of images by state and visibility.
  The metric contains ``state`` and ``visibility`` field.
* ``openstack_glance_snapshots``, the number of snapshot images by state and
  visibility. The metric contains ``state`` and ``visibility`` field.
* ``openstack_glance_images_size``, the total size (in bytes) of images by
  state and visibility. The metric contains ``state`` and ``visibility`` field.
* ``openstack_glance_snapshots_size``, the total size (in bytes) of snapshots
  by state and visibility. The metric contains ``state`` and ``visibility``
  field.

``state`` is one of 'queued', 'saving', 'active', 'killed', 'deleted',
'pending_delete'. ``visibility`` is either 'public' or 'private'.

Network
^^^^^^^

These metrics are retrieved from the Neutron API.

* ``openstack_neutron_networks``, the number of virtual networks by state. The metric contains a ``state`` field.
* ``openstack_neutron_subnets``, the number of virtual subnets.
* ``openstack_neutron_ports``, the number of virtual ports by owner and state. The metric contains ``owner`` and ``state`` fields.
* ``openstack_neutron_routers``, the number of virtual routers by state. The metric contains a ``state`` field.
* ``openstack_neutron_floatingips``, the total number of floating IP addresses.

``<state>`` is one of 'active', 'build', 'down' or 'error'.

``<owner>`` is one of 'compute', 'dhcp', 'floatingip', 'floatingip_agent_gateway', 'router_interface', 'router_gateway', 'router_ha_interface', 'router_interface_distributed' or 'router_centralized_snat'.

These metrics are retrieved from the Neutron database.

.. _network-agent-state-metrics:

.. note:: These metrics are not collected when the Contrail plugin is deployed.

* ``openstack_neutron_agents``, the total number of Neutron agents by service
  and state. The metric contains ``service`` (one of 'dhcp', 'l3', 'metadata'
  or 'openvswitch') and ``state`` (one of 'up', 'down' or 'disabled') fields.

* ``openstack_neutron_agent``, the Neutron agent state (either 0 for 'up', 1 for 'down' or 2 for 'disabled').
  The metric contains a ``service`` field (one of 'dhcp', 'l3', 'metadata' or 'openvswitch'),
  and a ``state`` field (one of 'up', 'down' or 'disabled').

API response times
^^^^^^^^^^^^^^^^^^

* ``openstack_<service>_http_responses``, the time (in second) it took to serve the HTTP request. The metric contains ``http_method`` (eg 'GET', 'POST', and so forth) and ``http_status`` (eg '200', '404', and so forth) fields.

``<service>`` is one of 'cinder', 'glance', 'heat' 'keystone', 'neutron' or 'nova'.

Logs
^^^^

* ``log_messages``, the number of log messages per second for the given service and severity level. The metric contains ``service`` and ``severity`` (one of 'debug', 'info', ... ) fields.
