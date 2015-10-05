.. _RabbitMQ_metrics:

Service
^^^^^^^

* ``rabbitmq_status``, the status of the RabbitMQ service, 1 if it is
  responsive, 0 otherwise.

Cluster
^^^^^^^

* ``rabbitmq_connections``, total number of connections.
* ``rabbitmq_consumers``, total number of consumers.
* ``rabbitmq_exchanges``, total number of exchanges.
* ``rabbitmq_memory``, bytes of memory consumed by the Erlang process associated with all queues, including stack, heap and internal structures.
* ``rabbitmq_used_memory``, bytes of memory used by the whole RabbitMQ process.
* ``rabbitmq_remaining_memory``, the difference between ``rabbitmq_vm_memory_limit`` and ``rabbitmq_used_memory``.
* ``rabbitmq_messages``, total number of messages which are ready to be consumed or not yet acknowledged.
* ``rabbitmq_total_nodes``, total number of nodes in the cluster.
* ``rabbitmq_running_nodes``, total number of running nodes in the cluster.
* ``rabbitmq_queues``, total number of queues.
* ``rabbitmq_unmirrored_queues``, total number of queues that are not mirrored.
* ``rabbitmq_vm_memory_limit``, the maximum amount of memory allocated for RabbitMQ. When ``rabbitmq_used_memory`` uses more than this value, all producers are blocked.
* ``rabbitmq_disk_free_limit``, the minimum amount of free disk for RabbitMQ. When ``rabbitmq_disk_free`` drops below this value, all producers are blocked.
* ``rabbitmq_disk_free``, the disk free space.
* ``rabbitmq_remaining_disk``, the difference between ``rabbitmq_disk_free`` and ``rabbitmq_disk_free_limit``.


Queues
^^^^^^

All metrics have a ``queue`` field which contains the name of the RabbitMQ queue.

* ``rabbitmq_queue_consumers``, number of consumers for a given queue.
* ``rabbitmq_queue_memory``, bytes of memory consumed by the Erlang process associated with the queue, including stack, heap and internal structures.
* ``rabbitmq_queue_messages``, number of messages which are ready to be consumed or not yet acknowledged for the given queue.
