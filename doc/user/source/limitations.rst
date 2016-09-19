.. _plugin_limitations:

Limitations
-----------

The StackLight Collector plugin 0.10.1 has the following limitations:

* The plugin is not compatible with an OpenStack environment deployed with
  nova-network.

* When you re-execute tasks on deployed nodes using the Fuel CLI, the
  *collectd* processes will be restarted on these nodes during the
  post-deployment phase.
  See `bug #1570850 <https://bugs.launchpad.net/lma-toolchain/+bug/1570850>`_.