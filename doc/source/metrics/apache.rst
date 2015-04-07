.. _Apache_metrics:

* ``apache.status``, the status of the Apache service, 1 if it is responsive, 0
  otherwise.
* ``apache.bytes``, the number of bytes per second transmitted by the server.
* ``apache.requests``, the number of requests processed per second.
* ``apache.connections``, the current number of active connections.
* ``apache.idle_workers``, the current number of idle workers.
* ``apache.workers.<state>``, the current number of workers by state.

``<state>`` is one of ``closing``, ``dnslookup``, ``finishing``,
``idle_cleanup``, ``keepalive``, ``logging``, ``open``, ``reading``,
``sending``, ``starting``, ``waiting``.
