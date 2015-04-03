.. _pacemaker-metrics:

Ressource location
^^^^^^^^^^^^^^^^^^

* ``pacemaker.resource.<resource-name>.active``, the resource is located on the
  node reporting the metric if value is ``1`` else ``0``.
* ``pacemaker.resource.<resource-name>.node_active``, the name of the node where
  the resource is located.

``<resource-name>`` is the name of the resource (ie. vip__public)
