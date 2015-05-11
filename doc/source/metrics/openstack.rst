.. _openstack_metrics:

Service checks
^^^^^^^^^^^^^^
.. _service_checks:

* ``openstack.<service>.check_api``, the service's API status, 1 if it is responsive, 0 otherwise.

``<service>`` is one of the following services with their respective resource checks:
* 'nova': '/'
* 'cinder': '/'
* 'cinderv2': '/'
* 'glance': '/'
* 'heat': '/'
* 'keystone': '/'
* 'neutron': '/'
* 'ceilometer': '/v2/capabilities'
* 'swift': '/healthcheck'
* 'swift_s3': '/healthcheck'

Compute
^^^^^^^

These metrics are emitted per compute node.

* ``openstack.nova.instance_creation_time``, the time (in seconds) it took to launch a new instance.
* ``openstack.nova.instance_state.<state>``, the number of instances which entered this state (always 1).

These metrics are retrieved from the Nova API and represent the aggregated
values across all compute nodes.

* ``openstack.nova.total_free_disk``, the total amount of disk space (in GB) available for new instances.
* ``openstack.nova.total_used_disk``, the total amount of disk space (in GB) used by the instances.
* ``openstack.nova.total_free_ram``, the total amount of memory (in MB) available for new instances.
* ``openstack.nova.total_used_ram``, the total amount of memory (in MB) used by the instances.
* ``openstack.nova.total_free_vcpus``, the total number of virtual CPU available for new instances.
* ``openstack.nova.total_used_vcpus``, the total number of virtual CPU used by the instances.
* ``openstack.nova.total_running_instances``, the total number of running instances.
* ``openstack.nova.total_running_tasks``, the total number of tasks currently executed.

These metrics are retrieved from the Nova API.

* ``openstack.nova.instances.<state>``, the number of instances by state.

``<state>`` is one of 'active', 'deleted', 'error', 'paused', 'resumed', 'rescued', 'resized', 'shelved_offloaded' or 'suspended'.

These metrics are retrieved from the Nova database.

.. _compute-service-state-metrics:

* ``openstack.nova.services.<service>.<service_state>``, the total number of Nova
  services by state.

``<service>`` is one of service is one of 'compute', 'conductor', 'scheduler', 'cert' or 'consoleauth'.

``<service_state>`` is one of 'up', 'down' or 'disabled'.

The following status metrics are computed from other metrics including: :ref:`service checks <service_checks>`,
:ref:`HAproxy servers <haproxy_backend_metric>` and :ref:`service states <compute-service-state-metrics>`.

Their value is one of '0' (ok), '1' (degraded), '2' (down) or '3' (unknown).

* ``openstack.nova.services.<service>.status``, status of Nova services computed from ``openstack.nova.services.<service>.<service_state>``.
* ``openstack.nova.api.<backend>.status``, status of the API services located behind the HAProxy load-balancer,
  computed from ``haproxy.backend.nova-*.servers.(up|down)``.
* ``openstack.nova.status``, the general status of the Nova service which is computed using the previous metrics and the ``openstack.nova.check_api`` metric.

Identity
^^^^^^^^

These metrics are retrieved from the Keystone API.

* ``openstack.keystone.roles``, the total number of roles.
* ``openstack.keystone.tenants.<state>``, the number of tenants by state.
* ``openstack.keystone.users.<state>``, the number of users by state.

``<state>`` is one of 'disabled' or 'enabled'.

The following status metrics are computed from other metrics: :ref:`service checks <service_checks>` and
:ref:`HAproxy servers <haproxy_backend_metric>`.

Their value is one of '0' (ok), '1' (degraded), '2' (down) or '3' (unknown).

* ``openstack.keystone.api.<backend>.status``, status of the API services located behind the HAProxy load-balancer, computed from ``haproxy.backend.keystone-*.servers.(up|down)``.
* ``openstack.keystone.status``, the general status of the Keystone service which is computed using the previous metric and the ``openstack.keystone.check_api`` metric.

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

These metrics are retrieved from the Cinder database.

.. _volume-service-state-metrics:

* ``openstack.cinder.services.<service>.<service_state>``, the total number of Cinder
  services by state.

``<service>`` is one of service is one of 'volume', 'backup', 'scheduler'.

``<service_state>`` is one of 'up', 'down' or 'disabled'.

The following status metrics are computed from other metrics including: :ref:`service checks <service_checks>`,
:ref:`HAproxy servers <haproxy_backend_metric>` and :ref:`service states <volume-service-state-metrics>`.

Their value is one of '0' (ok), '1' (degraded), '2' (down) or '3' (unknown).

* ``openstack.cinder.services.<service>.status``, status of Cinder services computed from ``openstack.cinder.services.<service>.<service_state>``.
* ``openstack.cinder.api.<backend>.status``, status of the API services located behind the HAProxy load-balancer,
  computed from ``haproxy.backend.cinder-api.servers.(up|down)``.
* ``openstack.cinder.status``, the general status of the Cinder service which is computed using the previous metrics and the ``openstack.cinder.check_api`` metric.

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

The following status metrics are computed from other metrics including: :ref:`service checks <service_checks>` and
:ref:`HAproxy servers <haproxy_backend_metric>`.

Their value is one of '0' (ok), '1' (degraded), '2' (down) or '3' (unknown).

* ``openstack.glance.api.<backend>.status``, status of the API services located behind the HAProxy load-balancer,
  computed from ``haproxy.backend.glance-*.servers.(up|down)``.
* ``openstack.glance.status``, the general status of the Glance service which is computed using the previous metric and the ``openstack.glance.check_api`` metric.

Network
^^^^^^^

These metrics are retrieved from the Neutron API.

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

``<state>`` is one of 'active', 'build', 'down' or 'error'.

``<owner>`` is one of 'compute', 'dhcp', 'floatingip', 'floatingip_agent_gateway', 'router_interface', 'router_gateway', 'router_ha_interface', 'router_interface_distributed' or 'router_centralized_snat'.

These metrics are retrieved from the Neutron database.

.. _network-agent-state-metrics:

* ``openstack.neutron.agents.<agent_type>.<agent_state>``, the total number of Neutron agents by agent type and state.

``<agent_type>`` is one of 'dhcp', 'l3', 'metadata' or 'openvswitch'.

``<agent_state>`` is one of 'up', 'down' or 'disabled'.

The following status metrics are computed from other metrics including: :ref:`service checks <service_checks>`,
:ref:`HAproxy servers <haproxy_backend_metric>` and :ref:`agent states <network-agent-state-metrics>`.

Their value is one of '0' (ok), '1' (degraded), '2' (down) or '3' (unknown).

* ``openstack.neutron.agents.<agent_type>.status``, status of Neutron services computed from metric ``openstack.neutron.agents.<agent_type>.<agent_state>``.
* ``openstack.neutron.api.neutron.status``, status f the API services located behind the HAProxy load-balancer,
  computed from ``haproxy.backend.neutron.servers.(up|down)``.
* ``openstack.neutron.status``, the general status of the Neutron service which is computed using the previous metrics and the ``openstack.neutron.check_api`` metric.

API response times
^^^^^^^^^^^^^^^^^^

* ``openstack.<service>.http.<HTTP method>.<HTTP status>``, the time (in second) it took to serve the HTTP request.

``<service>`` is one of 'cinder', 'glance', 'heat' 'keystone', 'neutron' or 'nova'.

``<HTTP method>`` is the HTTP method name, eg 'GET', 'POST' and so on.

``<HTTP status>`` is a 3-digit string representing the HTTP response code, eg '200', '404' and so on.
