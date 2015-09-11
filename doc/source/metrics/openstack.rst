.. _openstack_metrics:

Service checks
^^^^^^^^^^^^^^
.. _service_checks:

* ``openstack_<api>_check_api``, the service's API status, 1 if it is responsive, 0 otherwise.

``<api>`` is one of the following services with their respective resource checks:

* 'nova': '/'
* 'cinder': '/'
* 'cinder-v2': '/'
* 'glance': '/'
* 'heat': '/'
* 'heat-cfn': '/'
* 'keystone': '/'
* 'neutron': '/'
* 'ceilometer': '/v2/capabilities'
* 'swift': '/healthcheck'
* 'swift-s3': '/healthcheck'

.. note:: All checks are performed without authentication except for Ceilometer.

Compute
^^^^^^^

These metrics are emitted per compute node.

* ``openstack_nova_instance_creation_time``, the time (in seconds) it took to launch a new instance.
* ``openstack_nova_instance_state``, the count of instances which entered a given state (the value is always 1). The metric contains a ``state`` field.

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

* ``openstack_nova_services.<service>.<service_state>``, the total count of Nova
  services by state. The metric contains a ``service`` field (one of 'compute',
  'conductor', 'scheduler', 'cert' or 'consoleauth') and a ``state`` field (one
  of 'up', 'down' or 'disabled').

Status metrics, see :ref:`service status <service_status>` for details:

* ``openstack_nova_services_status``, status of Nova services (workers)
  computed from ``openstack_nova_services``.
* ``openstack_nova_pool_status``, status of API services located behind the HAProxy load-balancer,
  computed from ``haproxy_backend_servers``.
* ``openstack_nova_status``, the global status of the Nova service.

Identity
^^^^^^^^

These metrics are retrieved from the Keystone API.

* ``openstack_keystone_roles``, the total number of roles.
* ``openstack_keystone_tenants``, the number of tenants by state. The metric
  contains a ``state`` field (either 'enabled' or 'disabled').
* ``openstack_keystone_users``, the number of users by state. The metric
  contains a ``state`` field (either 'enabled' or 'disabled').

Status metrics, see :ref:`service status <service_status>` for details:

* ``openstack_keystone_pool_status``, status of API services located behind the
  HAProxy load-balancer, computed from ``haproxy_backend_servers``.
* ``openstack_keystone_status``, the global status of the Keystone service.

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

Status metrics, see :ref:`service status <service_status>` for details:

* ``openstack_cinder_services_status``, status of Cinder services (workers) computed from ``openstack_cinder_services``.
* ``openstack_cinder_pool_status``, status of API services located behind the HAProxy load-balancer,
  computed from ``haproxy_backend_servers``.
* ``openstack_cinder_status``, the global status of the Cinder.

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

Status metrics, see :ref:`service status <service_status>` for details:

* ``openstack_glance_pool_status``, status of the API service located behind the HAProxy load-balancer,
  computed from ``haproxy_backend_servers``.
* ``openstack_glance_status``, the global status of the Glance service.

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

* ``openstack_neutron_agents``, the total number of Neutron agents by service
  and state. The metric contains ``service`` (one of 'dhcp', 'l3', 'metadata'
  or 'openvswitch') and ``state`` (one of 'up', 'down' or 'disabled') fields.

Status metrics, see :ref:`service status <service_status>` for details:

* ``openstack_neutron_agents_status``, status of Neutron services (workers) computed from metric ``openstack_neutron_agents``.
* ``openstack_neutron_pool_neutron_status``, status of the API service located behind the HAProxy load-balancer,
  computed from ``haproxy_backend_servers``.
* ``openstack_neutron_status``, the global status of the Neutron service.

API response times
^^^^^^^^^^^^^^^^^^

* ``openstack_<service>_http_responses``, the time (in second) it took to serve the HTTP request. The metric contains ``http_method`` (eg 'GET', 'POST', and so on) and ``http_status`` (eg '200', '404', and so on) fields.

``<service>`` is one of 'cinder', 'glance', 'heat' 'keystone', 'neutron' or 'nova'.


Service status
^^^^^^^^^^^^^^
.. _service_status:

.. note:: This section is obsolete and should be rewritten.

A **global status** is computed for each OpenStack service (``openstack.<service>.status``),
where the value is one of:

* 0, meaning OKAY
* 1, meaning WARN
* 2, meaning FAIL
* 3, meaning UNKNOWN (no metric to determine the status)

The **global status** of a service is based on its **underlying status**,
where the value is one of:

* 0, meaning UP
* 1, meaning DEGRADED
* 2, meaning DOWN
* 3, meaning UNKNOWN (no metric to determine the status)

**Underlying status**:

* ``openstack.<service>.endpoint.<api>.status``, status of all API of the service,
  based on related :ref:`service checks <service_checks>` (``openstack.<api>.check_api``).
  To notice that the endpoint status cannot be DEGRADED.

* ``openstack.<service>.pool.<backend>.status``, status of all HAproxy backend pools,
  based on related status of :ref:`HAproxy server states <haproxy_backend_metric>` (``haproxy.backend.<backend>.servers.(up|down)``).
  The status is

  * OKAY if all servers are UP.
  * DEGRADED if one or more servers are DOWN and at least one server is UP.
  * DOWN if all servers are DOWN.

Furhtermore, the global statutes of the *compute*, *volume* and *network* services
are also based respectively on these underlying 'worker' status:

* ``openstack.nova.services.<service>.status``, status of Nova services computed from ``openstack.nova.services.<service>.<service_state>``,
  see :ref:`Nova service states <compute-service-state-metrics>`.
* ``openstack.cinder.services.<service>.status``, status of Nova services computed from ``openstack.cinder.services.<service>.<service_state>``,
  see :ref:`Cinder service states <volume-service-state-metrics>`.
* ``openstack_neutron.agents.<agent_type>.status``, status of Neutron agents computed from ``openstack.neutron.agents.<agent_type>.<agent_state>``,
  see :ref:`Neutron agent states <network-agent-state-metrics>`.

The status of these 3 above is determined as follow:

* OK if all workers are UP and there is no worker DOWN, note that DISABLED workers are ignored.
* DEGRADED if one or more workers are DOWN and at least one worker is UP.
* DOWN if there is no UP worker.

The **global status** determination follows these simple rules:

* OK if all underlying status are OK.
* WARN if one of underlying status is DEGRADED.
* FAIL if one of underlying status is DOWN.
* UNKNOWN if one of underlying status is UNKNOWN.
