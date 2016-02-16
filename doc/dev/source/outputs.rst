.. _outputs:

==================
Supported Outputs
==================

The LMA collector can forward part or all of the processed Heka messages to any
kind of external system, provided that the system supports a protocol-based
interface such as HTTP, SMTP or AMQP.

The supported backends are described hereunder.

.. _elasticsearch_output:

Elasticsearch
=============

The LMA collector is able to send :ref:`logs` and :ref:`notifications` to
`Elasticsearch <http://elasticsearch.org/>`_.

There is one index per day and per type of message:

* Index for log messages is ``log-<YYYY-MM-DD>``.

* Index for notification messages is ``notification-<YYYY-MM-DD>``.

.. _influxdb_output:

InfluxDB
========

The LMA collector is able to send :ref:`metrics` to `InfluxDB
<http://influxdb.com/>`_.

A metric message is stored into a measurement whose name is taken from
`Fields[name]`. The datapoint's timestamp is taken from the `Timestamp` field
and `Fields[value]` is stored as the `value` field. Note that numerical values
are always encoded as float numbers.

Some tags are associated to all measurements:

* `deployment_id`

* `hostname`

If the metric message contains a non-empty `Fields[tag_fields]` list, the
items listed in this field are encoded as additional key-value tags.

For instance, lets take the following Heka message::

    2015/09/15 16:16:05
    :Timestamp: 2015-09-15 16:15:37.645999872 +0000 UTC
    :Type: metric
    :Hostname: node-1
    :Pid: 15595
    :Uuid: e67f91c5-259b-489f-adfa-8eea0b389eb2
    :Logger: collectd
    :Payload: {"type":"cpu","values":[0],"type_instance":"idle","dsnames":["value"],
              "plugin":"cpu","time":1442333737.646,"interval":10,"host":"node-1",
              "dstypes":["derive"],"plugin_instance":"0"}
    :EnvVersion:
    :Severity: 6
    :Fields:
        | name:"type" type:string value:"derive"
        | name:"source" type:string value:"cpu"
        | name:"deployment_id" type:string value:"1"
        | name:"openstack_roles" type:string value:"primary-controller"
        | name:"openstack_release" type:string value:"2015.1.0-7.0"
        | name:"tag_fields" type:string value:"cpu_number"
        | name:"openstack_region" type:string value:"RegionOne"
        | name:"name" type:string value:"cpu_idle"
        | name:"hostname" type:string value:"node-1"
        | name:"value" type:double value:0
        | name:"environment_label" type:string value:"deploy_lma_infra_alerting_ha"
        | name:"interval" type:double value:10
        | name:"cpu_number" type:string value:"95"

Using the InfluxDB line protocol, it would be encoded like this::

    cpu_idle,cpu_number=0,deployment_id=1,hostname=node-1 value=95.000000 1442333737645


