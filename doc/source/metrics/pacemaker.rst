.. _pacemaker-metrics:

Resource location
^^^^^^^^^^^^^^^^^

* ``pacemaker.resource.<resource-name>.active``,  ``1`` when the resource is
  located on the host reporting the metric, ``0`` otherwise.

``<resource-name>`` is one of 'vip__public', 'vip__management',
  'vip__public_vrouter' or 'vip__management_vrouter'.
