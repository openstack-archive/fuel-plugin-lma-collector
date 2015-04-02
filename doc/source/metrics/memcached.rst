.. _memcached_metrics:

* ``memcached.status``, the status of the memcached service, 1 if it is
  responsive, 0 otherwise.
* ``memcached.command.flush``, cumulative number of flush reqs.
* ``memcached.command.get``, cumulative number of retrieval reqs.
* ``memcached.command.set``, cumulative number of storage reqs.
* ``memcached.command.touch``, cumulative number of touch reqs.
* ``memcached.connections.current``, number of open connections.
* ``memcached.items.current``, current number of items stored.
* ``memcached.octets.rx``, total number of bytes read by this server from network.
* ``memcached.octets.tx``, total number of bytes sent by this server to network.
* ``memcached.ops.decr_hits``, number of successful decr reqs.
* ``memcached.ops.decr_misses``, number of decr reqs against missing keys.
* ``memcached.ops.evictions``, number of valid items removed from cache to free memory for new items.
* ``memcached.ops.hits``, number of keys that have been requested.
* ``memcached.ops.incr_hits``, number of successful incr reqs.
* ``memcached.ops.incr_misses``, number of successful incr reqs.
* ``memcached.ops.misses``, number of items that have been requested and not found.
* ``memcached.df.cache.used``, current number of bytes used to store items.
* ``memcached.df.cache.free``, current number of free bytes to store items.
* ``memcached.percent.hitratio``, percentage of get command hits (in cache).


See `memcached documentation`_ for further details.

.. _memcached documentation: https://github.com/memcached/memcached/blob/master/doc/protocol.txt#L488
