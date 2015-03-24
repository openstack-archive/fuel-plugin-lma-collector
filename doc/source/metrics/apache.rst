.. _Apache_metrics:

* ``apache.bytes"``, bytes transferred.
* ``apache.connections"``, number of connections.
* ``apache.idle_workers"``, the number of idle workers.
* ``apache.requests"``, the number of Apache Accesses.
* ``apache.workers.<state>"``, the number of workers by state.

``<state>`` is one of ``closing"``, ``dnslookup"``, ``finishing"``, ``idle_cleanup"``, ``keepalive"``, ``logging"``, ``open"``, ``reading"``, ``sending"``, ``starting"``, ``waiting"``.
