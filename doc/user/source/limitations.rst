.. _plugin_limitations:

Limitations
-----------

The StackLight Collector plugin 0.10.3 has the following limitations:

* The plugin is not compatible with an OpenStack environment deployed with
  nova-network.

* When you re-execute tasks on deployed nodes using the Fuel CLI, the
  *collectd* processes will be restarted on these nodes during the
  post-deployment phase.
  See `bug #1570850 <https://bugs.launchpad.net/lma-toolchain/+bug/1570850>`_.

* The deployment fails if you select "Sending alerts by email" in the Alerting
  section.  See `bug #1643542
  <https://bugs.launchpad.net/lma-toolchain/+bug/1643542>`_.
