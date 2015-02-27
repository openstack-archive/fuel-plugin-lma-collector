.. _openstack_metrics:

Service checks
^^^^^^^^^^^^^^

* ``openstack.<service>.check_api``, the service's API status, 1 if it is responsive, 0 otherwise.

``<service>`` is one of 'cinder', 'glance', 'heat' 'keystone', 'neutron' or 'nova'.

Compute
^^^^^^^

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

``<state>`` is one of 'active', 'deleted', 'error', 'paused', 'resumed', 'rescued', 'resized', 'shelved_offloaded' or 'suspended'.

API response times
^^^^^^^^^^^^^^^^^^

* ``openstack.<service>.http.<HTTP method>.<HTTP status>``, the time (in second) it took to serve the HTTP response.

``<service>`` is one of 'cinder', 'glance', 'heat' 'keystone', 'neutron' or 'nova'.
``<HTTP method>`` is the HTTP method name, eg 'GET', 'POST' and so on.
``<HTTP status>`` is a 3-digit string representing the HTTP response code, eg '200', '404' and so on.
