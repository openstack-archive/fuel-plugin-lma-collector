.. _memcached_metrics:

* ``memcached_command_flush``, the cumulative number of flush reqs.
* ``memcached_command_get``, the cumulative number of retrieval reqs.
* ``memcached_command_set``, the cumulative number of storage reqs.
* ``memcached_command_touch``, the cumulative number of touch reqs.
* ``memcached_connections_current``, the number of open connections.
* ``memcached_df_cache_free``, the current number of free bytes to store items.
* ``memcached_df_cache_used``, the current number of bytes used to store items.
* ``memcached_items_current``, the current number of items stored.
* ``memcached_octets_rx``, the total number of bytes read by this server from
  the network.
* ``memcached_octets_tx``, the total number of bytes sent by this server to
  the network.
* ``memcached_ops_decr_hits``, the number of successful decr reqs.
* ``memcached_ops_decr_misses``, the number of decr reqs against missing keys.
* ``memcached_ops_evictions``, the number of valid items removed from cache to
  free memory for new items.
* ``memcached_ops_hits``, the number of keys that have been requested.
* ``memcached_ops_incr_hits``, the number of successful incr reqs.
* ``memcached_ops_incr_misses``, the number of successful incr reqs.
* ``memcached_ops_misses``, the number of items that have been requested and
  not found.
* ``memcached_percent_hitratio``, the percentage of get command hits (in cache).
* ``memcached_ps_cputime_syst``, the amount of time the processor worked on
  operating system's function related to the memcached process.
* ``memcached_ps_cputime_user``, the amount of time the processor worked for
  the memcached process.

For details, see the `Memcached documentation <https://github.com/memcached/memcached/blob/master/doc/protocol.txt#L488>`_.
