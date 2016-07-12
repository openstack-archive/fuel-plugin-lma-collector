.. _plugin_limitations:

Limitations
-----------

* The plugin is not compatible with an OpenStack environment deployed with nova-network.

* When you re-execute tasks on deployed nodes using the Fuel CLI, the *hekad* and
  *collectd* processes will be restarted on these nodes during the post-deployment
  phase. See `bug #1570850
  <https://bugs.launchpad.net/lma-toolchain/+bug/1570850>`_ for details.