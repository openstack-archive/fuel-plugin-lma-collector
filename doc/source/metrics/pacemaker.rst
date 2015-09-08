.. _pacemaker-metrics:

Resource location
^^^^^^^^^^^^^^^^^

* ``pacemaker_resource_local_active``,  ``1`` when the resource is located on
  the host reporting the metric, ``0`` otherwise. The metric contains a
  ``resource`` field which is one of 'vip__public', 'vip__management',
  'vip__public_vrouter' or 'vip__management_vrouter'.
