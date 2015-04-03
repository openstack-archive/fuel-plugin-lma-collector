.. _pacemaker-metrics:

Resource location
^^^^^^^^^^^^^^^^^

* ``pacemaker.resource.<resource-name>.active``,  ``1`` when the resource is
  located on the host reporting the metric, ``0`` otherwise.
* ``pacemaker.resource.<resource-name>.active_node``, the hostname where
  the resource is located.

``<resource-name>`` is one of 'vip__public' and 'vip__management'.
