.. _cluster_metrics:

The cluster metrics are emitted by the GSE plugins (See the :ref:`alarm_guide` for details).

* ``cluster_service_status``, the status of the service cluster.
  The metric contains a ``cluster_name`` field that identifies the service cluster.

* ``cluster_node_status``, the status of the node cluster.
  The metric contains a ``cluster_name`` field that identifies the node cluster.

* ``cluster_status``, the status of the global cluster.
  The metric contains a ``cluster_name`` field that identifies the global cluster.


The supported values for these metrics are:

* `0` for the *Okay* status.

* `1` for the *Warning* status.

* `2` for the *Unknown* status.

* `3` for the *Critical* status.

* `4` for the *Down* status.
