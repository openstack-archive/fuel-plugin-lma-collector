.. _pacemaker-metrics:

Cluster
^^^^^^^

* ``pacemaker_local_dc_active``, ``1`` when the Designated Controller (DC) is
  the local host, if not, then ``0``.

* ``pacemaker_dc`` [#f1]_, ``1`` when the Designated Controller (DC) is
  present, if not, then ``0``.
* ``pacemaker_quorum_status`` [#f1]_, ``1`` when the cluster's quorum is
  reached, if not, then ``0``.
* ``pacemaker_configured_nodes`` [#f1]_, the number of configured nodes in the
  cluster.
* ``pacemaker_configured_resources`` [#f1]_, the number of configured nodes in
  the cluster.

.. [#f1] this metric is only emitted from the node that is the Designated
   Controller (DC) of the Pacemaker cluster.

Node
^^^^
The following metrics are only emitted from the node that is the Designated
Controller (DC) of the Pacemaker cluster. They have a ``status`` field which is
one of 'offline', 'maintenance', or 'online':

* ``pacemaker_node_status``, the status of the node, ``0`` when offline, ``1``
  when in maintenance or ``2`` when online.
* ``pacemaker_node_count``, the total number of nodes with the given
  ``status``.
* ``pacemaker_node_percent``, the percentage of nodes with the given
  ``status``.

Resource
^^^^^^^^

* ``pacemaker_local_resource_active``, ``1`` when the resource is located on
  the host reporting the metric, if not, then ``0``. The metric contains a
  ``resource`` field which is one of 'vip__public', 'vip__management',
  'vip__vrouter_pub', or 'vip__vrouter'.

* ``pacemaker_resource_failures`` [#f2]_, the total number of failures that
  Pacemaker detected for the ``resource``. The counter is reset every time the
  collector restarts. The metric contains a ``resource`` field which one of
  'vip__management', 'vip__public', 'vip__vrouter_pub', 'vip__vrouter',
  'rabbitmq', 'mysqld' or 'haproxy'.

* ``pacemaker_resource_operations`` [#f2]_, the total number of operations that
  Pacemaker applied to the ``resource``. The counter is reset every time the
  collector restarts. The metric contains a ``resource`` field which one of
  'vip__management', 'vip__public', 'vip__vrouter_pub', 'vip__vrouter',
  'rabbitmq', 'mysqld' or 'haproxy'.

The following metrics have ``resource`` and ``status`` fields.

``status`` is one of 'offline', 'maintenance', or 'online'.

``resource`` is one of 'vip__management', 'vip__public', 'vip__vrouter_pub',
'vip__vrouter', 'rabbitmq', 'mysqld' or 'haproxy'.

* ``pacemaker_resource_count`` [#f2]_, the total number of instances for the given
  ``status`` and ``resource``.
* ``pacemaker_resource_percent`` [#f2]_, the percentage of instances for the given
  ``status`` and ``resource``.

.. [#f2] this metric is only emitted from the node that is the Designated
   Controller (DC) of the Pacemaker cluster.
