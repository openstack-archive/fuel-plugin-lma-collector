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
* ``rabbitmq_messages``, total number of messages which are ready to be consumed or not yet acknowledged.
* ``rabbitmq_total_nodes``, total number of nodes in the cluster.
* ``rabbitmq_running_nodes``, total number of running nodes in the cluster.
* ``rabbitmq_queues``, total number of queues.

Queues
^^^^^^

All metrics have a ``queue`` field which contains the name of the RabbitMQ queue.

* ``rabbitmq_queue_consumers``, number of consumers for a given queue.
* ``rabbitmq_queue_memory``, bytes of memory consumed by the Erlang process associated with the queue, including stack, heap and internal structures. 
* ``rabbitmq_queue_messages``, number of messages which are ready to be consumed or not yet acknowledged for the given queue.
