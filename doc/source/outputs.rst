.. _outputs:

=======
Outputs
=======

The LMA collector can forward part or all of the processed Heka messages to any
kind of external system, provided that the system supports a protocol-based
interface such as HTTP, SMTP or AMQP.

The supported backends are described hereunder.

.. _elasticsearch_output:

ElasticSearch
=============

The LMA collector is able to send :ref:`logs` and :ref:`notifications` to
`ElasticSearch <http://elasticsearch.org/>`_.

There is one index per day and per type of message:

* Index for log messages is ``log-<YYYY-MM-DD>``.

* Index for notification messages is ``notification-<YYYY-MM-DD>``.

.. _influxdb_output:

InfluxDB
========

The LMA collector is able to send :ref:`metrics` to `InfluxDB
<http://influxdb.com/>`_.

Metrics are stored in individual series per metric name and hostname. The name
of the serie is encoded as ``<Fields[hostname]>.<Fields[name]>``.
