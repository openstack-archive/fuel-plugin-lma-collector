.. _memcached_metrics:

* ``memcached.command.flush``, Cumulative number of flush reqs.
* ``memcached.command.get``, Cumulative number of retrieval reqs.
* ``memcached.command.set``, Cumulative number of storage reqs.
* ``memcached.command.touch``, Cumulative number of touch reqs.
* ``memcached.connections.current``, Number of open connections.
* ``memcached.items.current``, Current number of items stored.
* ``memcached.octets.rx``, Total number of bytes read by this server from network.
* ``memcached.octets.tx``, Total number of bytes sent by this server to network.
* ``memcached.ops.decr_hits``, Number of successful decr reqs.
* ``memcached.ops.decr_misses``, Number of decr reqs against missing keys.
* ``memcached.ops.evictions``, Number of valid items removed from cache to free memory for new items.
* ``memcached.ops.hits``, Number of keys that have been requested.
* ``memcached.ops.incr_hits``, Number of successful incr reqs.
* ``memcached.ops.incr_misses``, Number of successful incr reqs.
* ``memcached.ops.misses``, Number of items that have been requested and not found.


See `memcached documentation`_ for further details.

.. _memcached documentation: https://github.com/memcached/memcached/blob/master/doc/protocol.txt#L488
