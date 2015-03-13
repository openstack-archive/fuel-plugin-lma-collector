.. _memcached_metrics:

* ``memcached_command.flush``, Cumulative number of flush reqs.
* ``memcached_command.get``, Cumulative number of retrieval reqs.
* ``memcached_command.set``, Cumulative number of storage reqs.
* ``memcached_command.touch``, Cumulative number of touch reqs.
* ``memcached_connections.current``, Number of open connections.
* ``memcached_items.current``, Current number of items stored.
* ``memcached_octets.rx``, Total number of bytes read by this server from network.
* ``memcached_octets.tx``, Total number of bytes sent by this server to network.
* ``memcached_ops.decr_hits``, Number of successful decr reqs.
* ``memcached_ops.decr_misses``, Number of decr reqs against missing keys.
* ``memcached_ops.evictions``, Number of valid items removed from cache to free memory for new items.
* ``memcached_ops.hits``, Number of keys that have been requested.
* ``memcached_ops.incr_hits``, Number of successful incr reqs.
* ``memcached_ops.incr_misses``, Number of successful incr reqs.
* ``memcached_ops.misses``, Number of items that have been requested and not found.


See `memcached documentation`_ for further details.

.. _memcached documentation: https://github.com/memcached/memcached/blob/master/doc/protocol.txt#L488
