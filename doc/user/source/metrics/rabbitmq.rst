.. _RabbitMQ_metrics:

Cluster
^^^^^^^

* ``rabbitmq_connections``, the total number of connections.
* ``rabbitmq_consumers``, the total number of consumers.
* ``rabbitmq_channels``, the total number of channels.
* ``rabbitmq_exchanges``, the total number of exchanges.
* ``rabbitmq_messages``, the total number of messages which are ready to be
  consumed or not yet acknowledged.
* ``rabbitmq_queues``, the total number of queues.
* ``rabbitmq_running_nodes``, the total number of running nodes in the cluster.
* ``rabbitmq_disk_free``, the free disk space.
* ``rabbitmq_disk_free_limit``, the minimum amount of free disk space for
  RabbitMQ.
  When ``rabbitmq_disk_free`` drops below this value, all producers are blocked.
* ``rabbitmq_remaining_disk``, the difference between ``rabbitmq_disk_free``
  and ``rabbitmq_disk_free_limit``.
* ``rabbitmq_used_memory``, bytes of memory used by the whole RabbitMQ process.
* ``rabbitmq_vm_memory_limit``, the maximum amount of memory allocated for
  RabbitMQ. When ``rabbitmq_used_memory`` uses more than this value, all
  producers are blocked.
* ``rabbitmq_remaining_memory``, the difference between
  ``rabbitmq_vm_memory_limit`` and ``rabbitmq_used_memory``.
