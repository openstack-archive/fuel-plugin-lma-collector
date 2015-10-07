.. _memcached_metrics:

* ``memcached_command_flush``, cumulative number of flush reqs.
* ``memcached_command_get``, cumulative number of retrieval reqs.
* ``memcached_command_set``, cumulative number of storage reqs.
* ``memcached_command_touch``, cumulative number of touch reqs.
* ``memcached_connections_current``, number of open connections.
* ``memcached_items_current``, current number of items stored.
* ``memcached_octets_rx``, total number of bytes read by this server from network.
* ``memcached_octets_tx``, total number of bytes sent by this server to network.
* ``memcached_ops_decr_hits``, number of successful decr reqs.
* ``memcached_ops_decr_misses``, number of decr reqs against missing keys.
* ``memcached_ops_evictions``, number of valid items removed from cache to free memory for new items.
* ``memcached_ops_hits``, number of keys that have been requested.
* ``memcached_ops_incr_hits``, number of successful incr reqs.
* ``memcached_ops_incr_misses``, number of successful incr reqs.
* ``memcached_ops_misses``, number of items that have been requested and not found.
* ``memcached_df_cache_used``, current number of bytes used to store items.
* ``memcached_df_cache_free``, current number of free bytes to store items.
* ``memcached_percent_hitratio``, percentage of get command hits (in cache).


See `memcached documentation`_ for further details.

.. _memcached documentation: https://github.com/memcached/memcached/blob/master/doc/protocol.txt#L488
