.. _pacemaker-metrics:

Cluster
^^^^^^^

* ``pacemaker_dc``, ``1`` when the Designated Controller (DC) is present, if
  not, then ``0``.
* ``pacemaker_quorum_status``, ``1`` when the cluster's quorum is reached, if
  not, then ``0``.
* ``pacemaker_configured_nodes``, the number of configured nodes in the
  cluster.
* ``pacemaker_configured_resources``, the number of configured nodes in the
  cluster.

Node
^^^^

The following metrics have a ``status`` field which is one of 'offline',
'maintenance', or 'online':

* ``pacemaker_node_status``, the status of the node, ``0`` when offline, ``1``
  when in maintenance or ``2`` when online.
* ``pacemaker_node_count``, the total number of nodes with the given
  ``status``.
* ``pacemaker_node_percent``, the percentage of nodes with the given
  ``status``.

Resource
^^^^^^^^

The following metrics have a ``resource`` and ``status`` fields.

``status`` is one of 'offline', 'maintenance', or 'online'.

``resource`` is one of 'vip__management', 'vip__public', 'vip__vrouter_pub',
'vip__vrouter', 'rabbitmq', 'mysqld' or 'haproxy'.

* ``pacemaker_resource_count``, the total number of instances for the given
  ``status`` and ``resource``.
* ``pacemaker_resource_percent``, the percentage of instances for the given
  ``status`` and ``resource``.

Resource location
^^^^^^^^^^^^^^^^^

* ``pacemaker_resource_local_active``,  ``1`` when the resource is located on
  the host reporting the metric, if not, then ``0``. The metric contains a
  ``resource`` field which is one of 'vip__public', 'vip__management',
  'vip__vrouter_pub', or 'vip__vrouter'.
