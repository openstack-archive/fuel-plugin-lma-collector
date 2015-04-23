.. _RabbitMQ_metrics:

Service
^^^^^^^

* ``rabbitmq.status``, the status of the RabbitMQ service, 0 if it is
  responsive, 2 otherwise.

Cluster
^^^^^^^

* ``rabbitmq.connections``, Number of connections.
* ``rabbitmq.consumers``, Number of consumers.
* ``rabbitmq.exchanges``, Number of exchanges.
* ``rabbitmq.memory``, Bytes of memory consumed by the Erlang process associated with all queues, including stack, heap and internal structures.
* ``rabbitmq.messages``, Total number of messages which are ready to be consumed or not yet acknowledged.
* ``rabbitmq.total_nodes``, Number of nodes in the cluster.
* ``rabbitmq.running_nodes``, Number of running nodes in the cluster.
* ``rabbitmq.queues``, Number of queues.

Queues
^^^^^^

* ``rabbitmq.<name_of_the_queue>.consumers``, Number of consumers.
* ``rabbitmq.<name_of_the_queue>.memory``, Bytes of memory consumed by the Erlang process associated with the queue, including stack, heap and internal structures.
* ``rabbitmq.<name_of_the_queue>.messages``, Number of messages which are ready to be consumed or not yet acknowledged.
