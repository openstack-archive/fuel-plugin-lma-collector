.. _mysql_metrics:

Commands
^^^^^^^^

The **mysql_commands.** metrics report how many times per second each statement has been executed.

* ``mysql_commands.admin_commands``, the number of ADMIN statements.
* ``mysql_commands.change_db``, the number of USE statements.
* ``mysql_commands.commit``, the number of COMMIT statements.
* ``mysql_commands.flush``, the number of FLUSH statements.
* ``mysql_commands.insert``, the number of INSERT statements.
* ``mysql_commands.rollback``, the number of ROLLBACK statements.
* ``mysql_commands.select``, the number of SELECT statements.
* ``mysql_commands.set_option``, the number of SET statements.
* ``mysql_commands.show_collations``, the number of SHOW COLLATION statements.
* ``mysql_commands.show_databases``, the number of SHOW DATABASES statements.
* ``mysql_commands.show_fields``, the number of SHOW FIELDS statements.
* ``mysql_commands.show_master_status``, the number of SHOW MASTER STATUS statements.
* ``mysql_commands.show_status``, the number of SHOW STATUS statements.
* ``mysql_commands.show_tables``, the number of SHOW TABLES statements.
* ``mysql_commands.show_variables``, the number of SHOW VARIABLES statements.
* ``mysql_commands.show_warnings``, the number of SHOW WARNINGS statements.
* ``mysql_commands.update``, the number of UPDATE statements.

Handlers
^^^^^^^^

The **mysql_handler.** metrics report how many times per second each handler has been executed.

* ``mysql_handler.commit``, the number of internal COMMIT statements.
* ``mysql_handler.delete``, the number of internal DELETE statements.
* ``mysql_handler.external_lock``, the number of external lock.
* ``mysql_handler.read_first``, the number of times the first entry in an index was read.
* ``mysql_handler.read_key``, the number of requests to read a row based on a key.
* ``mysql_handler.read_next``, the number of requests to read the next row in key order.
* ``mysql_handler.read_prev``, the number of requests to read the previous row in key order.
* ``mysql_handler.read_rnd``, the number of requests to read a row based on a fixed position.
* ``mysql_handler.read_rnd_next``, the number of requests to read the next row in the data file.
* ``mysql_handler.rollback``, the number of requests for a storage engine to perform rollback operation.
* ``mysql_handler.update``, the number of requests to update a row in a table.
* ``mysql_handler.write``, the number of requests to insert a row in a table.

Locks
^^^^^

* ``mysql_locks.immediate``, the number of times per second the requests for table locks could be granted immediately.
* ``mysql_locks.waited``, the number of times per second the requests for table locks had to wait.

Network
^^^^^^^

* ``mysql_octets.rx``, the number of bytes received per second by the server.
* ``mysql_octets.tx``, the number of bytes sent per second by the server.

Query cache
^^^^^^^^^^^

.. note:: These metrics are not available if your environment is set to HA.

* ``mysql_qcache.hits``, the number of query cache hits per second.
* ``mysql_qcache.inserts``, the number of queries added to the query cache per second.
* ``mysql_qcache.lowmem_prunes``, the number of queries that were deleted from the query cache per second because of low memory.
* ``mysql_qcache.not_cached``, the number of noncached queries per second.
* ``mysql_qcache.queries_in_cache``, the number of queries registered in the query cache per second.

Threads
^^^^^^^

The **mysql_threads.created** metric is reported as a per-second rate.

* ``mysql_threads.cached``, the number of threads in the thread cache.
* ``mysql_threads.connected``, the number of currently open connections.
* ``mysql_threads.running``, the number of threads that are not sleeping.
* ``mysql_threads.created``, the number of threads created per second to handle connections.
