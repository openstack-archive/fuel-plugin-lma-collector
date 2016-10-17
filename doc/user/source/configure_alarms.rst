.. _configure_alarms:

Overview
--------

The process of running alarms in StackLight is not centralized, as it is often
the case in more conventional monitoring systems, but distributed across all
the StackLight Collectors.

Each Collector is individually responsible for monitoring the resources and
services that are deployed on the node and for reporting any anomaly or fault
it has detected to the Aggregator.

The anomaly and fault detection logic in StackLight is designed more like an
*expert system* in that the Collector and the Aggregator use artifacts we
can refer to as *facts* and *rules*.

The *facts* are the operational data ingested in the StackLight's
stream-processing pipeline. The *rules* are either alarm rules or aggregation
rules. They are declaratively defined in YAML files that can be modified.
Those rules are turned into a collection of Lua plugins that are executed by
the Collector and the Aggregator. They are generated dynamically using the
Puppet modules of the StackLight Collector Plugin.

The following are the two types of Lua plugins related to the processing of
alarms:

* The **AFD plugin** -- Anomaly and Fault Detection plugin
* The **GSE plugin** -- Global Status Evaluation plugin

These plugins create special types of metrics, as follows:

* The **AFD metric**, which contains information about the health status of a
  node or service in the OpenStack environment. The AFD metrics are sent on a
  regular basis to the Aggregator where they are further processed by the GSE
  plugins.

* The **GSE metric**, which contains information about the health status of a
  cluster in the OpenStack environment. A cluster is a logical grouping of
  nodes or services. We call them node clusters and service clusters hereafter.
  A service cluster can be anything like a cluster of API endpoints or a
  cluster of workers. A cluster of nodes is a grouping of nodes that have the
  same role. For example, *compute* or *storage*.

.. note:: The AFD and GSE metrics are new types of metrics introduced in
   StackLight version 0.8. They contain detailed information about the fault
   and anomalies detected by StackLight. For more information about the
   message structure of these metrics, refer to
   `Metrics section of the Developer Guide
   <http://lma-developer-guide.readthedocs.io/en/latest/metrics.html>`_.

The following figure shows the StackLight stream-processing pipeline workflow:

.. figure:: ../../images/AFD_and_GSE_message_flow.*
   :width: 800
   :alt: Message flow for the AFD and GSE metrics

.. raw:: latex

   \pagebreak

The AFD and GSE plugins
-----------------------

The current version of StackLight contains the following three types of GSE
plugins:

* The **Service Cluster GSE Plugin**, which receives AFD metrics for services
  from the AFD plugins.
* The **Node Cluster GSE Plugin**, which receives AFD metrics for nodes
  from the AFD plugins.
* The **Global Cluster GSE Plugin**, which receives GSE metrics from the
  GSE plugins above. It aggregates and correlates the GSE metrics to issue a
  global health status for the top-level clusters like Nova, MySQL, and others.

The health status exposed in the GSE metrics is as follows:

* ``Down``: One or several primary functions of a cluster has failed or is
  failing. For example, the API service for Nova or Cinder is not accessible.
* ``Critical``: One or several primary functions of a cluster are severely
  degraded. The quality of service delivered to the end user is severely
  impacted.
* ``Warning``: One or several primary functions of the cluster are slightly
  degraded. The quality of service delivered to the end user is slightly
  impacted.
* ``Unknown``: There is not enough data to infer the actual health status of
  the cluster.
* ``Okay``: None of the above was found to be true.

The AFD and GSE persisters
--------------------------

The AFD and GSE metrics are also consumed by other types of Lua plugins called
**persisters**:

* The **InfluxDB persister** transforms the GSE metrics into InfluxDB data
  points and Grafana annotations. They are used in Grafana to graph the health
  status of the OpenStack clusters.
* The **Elasticsearch persister** transforms the AFD metrics into events that
  are indexed in Elasticsearch. Using Kibana, these events can be searched to
  display a fault or an anomaly that occurred in the environment (not yet
  implemented).
* The **Nagios persister** transforms the GSE and AFD metrics into passive
  checks that are sent to Nagios for alerting and escalation.

New persisters can be easily created to feed other systems with the
operational insight contained in the AFD and GSE metrics.

.. _alarm_configuration:

Alarms configuration
--------------------

StackLight comes with a predefined set of alarm rules. We have tried to make
these rules as comprehensive and relevant as possible, but your mileage may
vary depending on the specifics of your OpenStack environment and monitoring
requirements. Therefore, it is possible to modify those predefined rules and
create new ones. To do so, modify the ``/etc/hiera/override/alarming.yaml``
file and apply the :ref:`Puppet manifest <puppet_apply>` that will dynamically
generate Lua plugins, known as the AFD Plugins, which are the actuators of the
alarm rules. But before you proceed, verify that understand the structure of
that file.

.. _alarm_structure:

Alarm structure
+++++++++++++++

An alarm rule is defined declaratively using the YAML syntax. For example::

    name: 'fs-warning'
    description: 'Filesystem free space is low'
    severity: 'warning'
    enabled: 'true'
    trigger:
      rules:
        - metric: fs_space_percent_free
          group_by: ['fs']
          relational_operator: '<'
          fields:
            fs: "=~ ceph/%d+$"
          threshold: 5
          window: 60
          periods: 0
          function: min

**Where**

| name:
|   Type: unicode
|   The name of the alarm definition

| description:
|   Type: unicode
|   A description of the alarm definition for humans

| severity:
|   Type: Enum(0 (down), 1 (critical) , 2 (warning))
|   The severity of the alarm

| enabled:
|   Type: Enum('true' | 'false')
|   The alarm is enabled or disabled

| relational_operator:
|    Type: Enum('lt' | '<' | 'gt' | '>' | 'lte' | '<=' | 'gte' | '>=')
|    The comparison against the alarm threshold

| rules
|    Type: list
|    List of rules to execute

| logical_operator
|    Type: Enum('and' | '&&' | 'or' | '||')
|    The conjunction relation for the alarm rules

| metric
|    Type: unicode
|    The name of the metric

| value
|   Type: unicode
|   The value of the metric

| group_by
|   Type: list
|   The list of fields to group by.
    For example, the alarm definition sample given above would apply the rule
    for each of the file system mount points associated with the
    ``fs_space_percent_free`` metric.

| fields
|   Type: list
|   List of field name/value pairs, also known as dimensions, used to select
    a particular device for the metric, such as a network interface name or
    file system mount point. If the value is not provided, then the rule
    applies to all the aggregated values for the specified field name.
    In the example above, the rule applies to the metrics having an **fs**
    dimension that matches the pattern **"=~ ceph/%d+$"**.
    See :ref:`Dimension pattern matching <dim_pattern_matching>`.

| window
|   Type: integer
|   The in-memory time-series analysis window in seconds

| periods
|   Type: integer
|   The number of prior time-series analysis window to compare the window with
|   (this is not implemented yet).

| function
|   Type: enum('last' | 'min' | 'max' | 'sum' | 'count' | 'avg' | 'median' | 'mode' | 'roc' | 'mww' | 'mww_nonparametric')
|   Where:
|     last:
|       returns the last value of all the values
|     min:
|       returns the minimum of all the values
|     max:
|       returns the maximum of all the values
|     sum:
|       returns the sum of all the values
|     count:
|       returns the number of metric observations
|     avg:
|       returns the arithmetic mean of all the values
|     median:
|       returns the middle value of all the values (not implemented yet)
|     mode:
|       returns the value that occurs most often in all the values
|       (not implemented yet)
|     roc:
|       The 'roc' function detects a significant rate of change when comparing
        current metrics values with historical data. To achieve this, it
        computes the average of the values in the current window and the
        average of the values in the window before the current window and
        compares the difference against the standard deviation of the
        historical window. The function returns ``true`` if the difference
        exceeds the standard deviation multiplied by the 'threshold' value.
        This function uses the rate of change algorithm already available in the
        anomaly detection module of Heka. It can only be applied to normal
        distributions. With an alarm rule using the 'roc' function, the
        'window' parameter specifies the duration in seconds of the current
        window, and the 'periods' parameter specifies the number of windows
        used for the historical data. You need at least one period and the
        'periods' parameter must not be zero. If you choose a period of 'p',
        the function will compute the rate of change using a historical data
        window of ('p' * window) seconds. For example, if you specify the
        following in the alarm rule:
|
|           window = 60
|           periods = 3
|           threshold = 1.5
|
|       the function will store in a circular buffer the value of the metrics
        received during the last 300 seconds (5 minutes) where:
|
|           Current window (CW) = 60 sec
|           Previous window (PW) = 60 sec
|           Historical window (HW) = 180 sec
|
|       and apply the following formula:
|
|            abs(avg(CW) - avg(PW)) > std(HW) * 1.5 ? true : false
|     mww:
|       returns the result (true, false) of the Mann-Whitney-Wilcoxon test
        function of Heka that can be used only with normal distributions (not
        implemented yet)
|     mww-nonparametric:
|       returns the result (true, false) of the Mann-Whitney-Wilcoxon test
        function of Heka that can be used with non-normal distributions (not
        implemented yet)
|     diff:
|       returns the difference between the last value and the first value of
        all the values

| threshold
|   Type: float
|   The threshold of the alarm rule

.. _dim_pattern_matching:

Dimension pattern matching
++++++++++++++++++++++++++

The alarming framework allows specifying alarms against metrics with a
filtering mechanism called **dimension pattern matching**. For details, see
the `specification <https://blueprints.launchpad.net/lma-toolchain/+spec/afd-alarm-fields-matching>`_.

The pattern matching is evaluated against the field/dimension specified by the
alarm rule::

  rules:
    - metric: foo_metric
      fields:
        my_dimension: <PATTERN MATCHING EXPRESSION>

where the pattern matching expression has the following format::

  EXP ::=  “<relation operator> string”

Expressions can be combined with logical operator(s)::

  EXP (<logical_operator> EXP, ..)

Where:

* Logical operators:

  * OR: **||**
  * AND: **&&**

* Relational operators:

  * Strings and numbers:

    * Equality: **==**
    * Not equal: **!=**

  * Strings only (for syntax, see `Lua pattern matching <http://www.lua.org/manual/5.1/manual.html#5.4.1>`_):

    * Match: **=~**
    * Negated match: **!~**

  * Numbers only:

    * Greater than: **>**
    * Greater than equals: **>=**
    * Less than: **<**
    * Less than equals: **<=**

Example:

+---------------+------------+----------+
| Value         | Pattern    | Matching |
+===============+============+==========+
| 10            | 10         | True     |
+---------------+------------+----------+
| 10            | == 10      | True     |
+---------------+------------+----------+
| 10            | != 42      | True     |
+---------------+------------+----------+
| 10            | > 42       | False    |
+---------------+------------+----------+
| 10            | >= 10      | True     |
+---------------+------------+----------+
| foo           | == foo     | True     |
+---------------+------------+----------+
| foo           | == bar     | False    |
+---------------+------------+----------+
| /var/log      | =~ /log$   | True     |
+---------------+------------+----------+
| /data         | !~ ^/data$ | False    |
+---------------+------------+----------+
| /var/log/data | !~ /data$  | False    |
+---------------+------------+----------+
| /var/log/data | !~ ^/data$ | True     |
+---------------+------------+----------+


Modify or create an alarm
+++++++++++++++++++++++++

To modify or create an alarm, edit the ``/etc/hiera/override/alarming.yaml``
file. This file has the following sections:

#. The ``alarms`` section contains a global list of alarms that are executed
   by the Collectors. These alarms are global to the LMA toolchain and should
   be kept identical on all nodes of the OpenStack environment. The following
   is another example of the definition of an alarm::

     alarms:
       - name: 'cpu-critical-controller'
         description: 'CPU critical on controller'
         severity: 'critical'
         enabled: 'true'
         trigger:
           logical_operator: 'or'
           rules:
              - metric: cpu_idle
                relational_operator: '<='
                threshold: 5
                window: 120
                periods: 0
                function: avg
              - metric: cpu_wait
                relational_operator: '>='
                threshold: 35
                window: 120
                periods: 0
                function: avg

   This alarm is called 'cpu-critical-controller'. It says that CPU activity
   is critical (severity: 'critical') if any of the rules in the alarm
   definition evaluate to true.

   The rule says that the alarm will evaluate to 'true' if the value of the
   metric ``cpu_idle`` has been in average (function: avg), below or equal
   (relational_operator: <=) to 5 for the last 2 minutes (window: 120).

   OR (logical_operator: 'or')

   If the value of the metric **cpu_wait** has been in average (function: avg),
   superior or equal (relational_operator: >=) to 35 for the last 2 minutes
   (window: 120)

   Note that these metrics are expressed in percentage.

   What alarms are executed on which node depends on the mapping between the
   alarm definition and the definition of a cluster as described in the
   following sections.

#. The ``node_cluster_roles`` section defines the mapping between the internal
   definition of a cluster of nodes and one or several Fuel roles.
   For example::

    node_cluster_roles:
      controller: ['primary-controller', 'controller']
      compute: ['compute']
      storage: ['cinder', 'ceph-osd']
      [ ... ]

   Creates a mapping between the 'primary-controller' and 'controller' Fuel
   roles, and the internal definition of a cluster of nodes called 'controller'.
   Likewise, the internal definition of a cluster of nodes called 'storage' is
   mapped to the 'cinder' and 'ceph-osd' Fuel roles. The internal definition
   of a cluster of nodes is used to assign the alarms to the relevant category
   of nodes. This mapping is also used to configure the **passive checks**
   in Nagios. Therefore, it is critically important to keep exactly the same
   copy of ``/etc/hiera/override/alarming.yaml`` across all nodes of the
   OpenStack environment including the node(s) where Nagios is installed.

#. The ``service_cluster_roles`` section defines the mapping between the
   internal definition of a cluster of services and one or several Fuel roles.
   For example::

     service_cluster_roles:
       rabbitmq: ['primary-controller', 'controller']
       nova-api: ['primary-controller', 'controller']
       elasticsearch: ['primary-elasticsearch_kibana', 'elasticsearch_kibana']
       [ ... ]

   Creates a mapping between the 'primary-controller' and 'controller' Fuel
   roles, and the internal definition of a cluster of services called 'rabbitmq'.
   Likewise, the internal definition of a cluster of services called
   'elasticsearch' is mapped to the 'primary-elasticsearch_kibana' and
   'elasticsearch_kibana' Fuel roles. As for the clusters of nodes, the
   internal definition of a cluster of services is used to assign the alarms
   to the relevant category of services.

#. The ``node_cluster_alarms`` section defines the mapping between the
   internal definition of a cluster of nodes and the alarms that are assigned
   to that category of nodes. For example::

     node_cluster_alarms:
        controller-nodes:
            apply_to_node: controller
            alerting: enabled
            members:
                cpu:
                    alarms: ['cpu-critical-controller', 'cpu-warning-controller']
                root-fs:
                    alarms: ['root-fs-critical', 'root-fs-warning']
                log-fs:
                    alarms: ['log-fs-critical', 'log-fs-warning']
                hdd-errors:
                    alerting: enabled_with_notification
                    alarms: ['hdd-errors-critical']

   Creates four alarm groups for the cluster of controller nodes:

   * The *cpu* alarm group is mapped to two alarms defined in the ``alarms``
     section known as the 'cpu-critical-controller' and
     'cpu-warning-controller' alarms. These alarms monitor the CPU on the
     controller nodes. The order matters here since the first alarm that
     evaluates to 'true' stops the evaluation. Therefore, it is important
     to start the list with the most critical alarms.
   * The *root-fs* alarm group is mapped to two alarms defined in the
     ``alarms`` section known as the 'root-fs-critical' and 'root-fs-warning'
     alarms. These alarms monitor the root file system on the controller nodes.
   * The *log-fs* alarm group is mapped to two alarms defined in the ``alarms``
     section known as the 'log-fs-critical' and 'log-fs-warning' alarms. These
     alarms monitor the file system where the logs are created on the
     controller nodes.
   * The *hdd-errors* alarm group is mapped to the 'hdd-errors-critical' alarm
     defined in the ``alarms`` section. This alarm monitors the ``kern.log``
     log entries containing critical IO errors detected by the kernel.
     The *hdd-error* alarm obtains the *enabled_with_notification* alerting
     attribute, meaning that the operator will be notified if any of the
     controller nodes encounters a disk failure. Other alarms do not trigger
     notification per node but at an aggregated cluster level.

   .. note:: An *alarm group* is a mere implementation artifact (although it
      has functional value) that is primarily used to distribute the alarms
      evaluation workload across several Lua plugins. Since the Lua plugins
      runtime is sandboxed within Heka, it is preferable to run smaller sets
      of alarms in different plugins rather than a large set of alarms in a
      single plugin. This is to avoid having alarms evaluation plugins
      shut down by Heka. Furthermore, the alarm groups are used to identify
      what is called a *source*. A *source* is a tuple in which we associate
      a cluster with an alarm group. For example, the tuple
      ['controller', 'cpu'] is a *source*. It associates a 'controller'
      cluster with the 'cpu' alarm group. The tuple ['controller', 'root-fs']
      is another *source* example. The *source* is used by the GSE Plugins to
      remember the AFD metrics it has received. If a GSE Plugin stops receiving
      AFD metrics it used to get, then the GSE Plugin infers that the health
      status of the cluster associated with the source is *Unknown*.

      This is evaluated every *ticker-interval*. By default, the
      *ticker interval* for the GSE Plugins is set to 10 seconds.

.. _aggreg_correl_config:

Aggregation and correlation configuration
-----------------------------------------

StackLight comes with a predefined set of aggregation rules and correlation
policies. However, you can create new aggregation rules and correlation
policies or modify the existing ones. To do so, modify the ``/etc/hiera/override/gse_filters.yaml`` file and apply the
:ref:`Puppet manifest <puppet_apply>` that will generate Lua plugins known as
the GSE Plugins, which are the actuators of these aggregation rules and
correlation policies. But before you proceed, verify that you understand the
structure of that file.

.. note:: As for ``/etc/hiera/override/alarming.yaml``, it is critically
   important to keep exactly the same copy of
   ``/etc/hiera/override/gse_filters.yaml`` across all the nodes of the
   OpenStack environment including the node(s) where Nagios is installed.

The aggregation rules and correlation policies are defined in the ``/etc/hiera/override/gse_filters.yaml`` configuration file.

This file has the following sections:

#. The ``gse_policies`` section contains the :ref:`health status correlation
   policies <gse_policies>` that apply to the node clusters and service
   clusters.
#. The ``gse_cluster_service`` section contains the :ref:`aggregation rules
   <gse_cluster_service>` for the service clusters. These aggregation rules
   are actuated by the Service Cluster GSE Plugin that runs on the Aggregator.
#. The ``gse_cluster_node`` section contains the :ref:`aggregation rules
   <gse_cluster_node>` for the node clusters. These aggregation rules are
   actuated by the Node Cluster GSE Plugin that runs on the Aggregator.
#. The ``gse_cluster_global`` section contains the :ref:`aggregation
   rules <gse_cluster_global>` for the so-called top-level clusters. A global
   cluster is a kind of logical construct of node clusters and service
   clusters. These aggregation rules are actuated by the Global Cluster GSE
   Plugin that runs on the Aggregator.

.. _gse_policies:

Health status policies
++++++++++++++++++++++

The correlation logic implemented by the GSE plugins is policy-based. The
policies define how the GSE plugins infer the health status of a cluster.

By default, there are two policies:

* The **highest_severity** policy defines that the cluster's status depends on
  the member with the highest severity, typically used for a cluster of
  services.
* The **majority_of_members** policy defines that the cluster is healthy as
  long as (N+1)/2 members of the cluster are healthy. This is typically used
  for clusters managed by Pacemaker.

A policy consists of a list of rules that are evaluated against the current
status of the cluster's members. When one of the rules matches, the cluster's
status gets the value associated with the rule and the evaluation stops. The
last rule of the list is usually a catch-all rule that defines the default
status if none of the previous rules matches.

The following example shows the policy rule definition::

   # The following rule definition reads as: "the cluster's status is critical
   # if more than 50% of its members are either down or critical"
   - status: critical
     trigger:
       logical_operator: or
       rules:
         - function: percent
           arguments: [ down, critical ]
           relational_operator: '>'
           threshold: 50

Where

| status:
|   Type: Enum(down, critical, warning, okay, unknown)
|   The cluster's status if the condition is met

| logical_operator
|    Type: Enum('and' | '&&' | 'or' | '||')
|    The conjunction relation for the condition rules

| rules
|    Type: list
|    List of condition rules to execute

| function
|   Type: enum('count' | 'percent')
|   Where:
|     count:
|       returns the *number of members* that match the passed value(s).
|     percent:
|       returns the *percentage of members* that match the passed value(s).

| arguments:
|    Type: list of status values
|    List of status values passed to the function

| relational_operator:
|    Type: Enum('lt' | '<' | 'gt' | '>' | 'lte' | '<=' | 'gte' | '>=')
|    The comparison against the threshold

| threshold
|   Type: float
|   The threshold value

Consider the policy called *highest_severity*::

  gse_policies:

    highest_severity:
      - status: down
        trigger:
          logical_operator: or
          rules:
            - function: count
              arguments: [ down ]
              relational_operator: '>'
              threshold: 0
      - status: critical
        trigger:
          logical_operator: or
          rules:
            - function: count
              arguments: [ critical ]
              relational_operator: '>'
              threshold: 0
      - status: warning
        trigger:
          logical_operator: or
          rules:
            - function: count
              arguments: [ warning ]
              relational_operator: '>'
              threshold: 0
      - status: okay
        trigger:
          logical_operator: or
          rules:
            - function: count
              arguments: [ okay ]
              relational_operator: '>'
              threshold: 0
      - status: unknown

The policy definition reads as follows:

* The status of the cluster is ``Down`` if the status of at least one
  cluster's member is ``Down``.

* Otherwise, the status of the cluster is ``Critical`` if the status of at
  least one cluster's member is ``Critical``.

* Otherwise, the status of the cluster is ``Warning`` if the status of at
  least one cluster's member is ``Warning``.

* Otherwise, the status of the cluster is ``Okay`` if the status of at least
  one cluster's entity is *Okay*.

* Otherwise, the status of the cluster is ``Unknown``.

.. _gse_cluster_service:

Service cluster aggregation rules
+++++++++++++++++++++++++++++++++

The service cluster aggregation rules are used to designate the members of a
service cluster along with the AFD metrics that must be taken into account to
derive a health status for the service cluster. The following is an example of
the service cluster aggregation rules::

  gse_cluster_service:
    input_message_types:
      - afd_service_metric
    aggregator_flag: true
    cluster_field: service
    member_field: source
    output_message_type: gse_service_cluster_metric
    output_metric_name: cluster_service_status
    interval: 10
    warm_up_period: 20
    alerting: enabled_with_notification
    clusters:
      nova-api:
        policy: highest_severity
        group_by: member
        members:
          - backends
          - endpoint
          - http_errors

Where

| input_message_types
|   Type: list
|   The type(s) of AFD metric messages consumed by the GSE plugin.

| aggregator_flag
|   Type: boolean
|   Whether or not the input messages are received from the upstream collectors.
    This is true for the Service and Node Cluster plugins and false for the
    Global Cluster plugin.

| cluster_field
|   Type: unicode
|   The field in the input message used by the GSE plugin to associate the
    AFD metrics to the clusters.

| member_field
|   Type: unicode
|   The field in the input message used by the GSE plugin to identify the
    cluster members.

| output_message_type
|   Type: unicode
|   The type of metric messages emitted by the GSE plugin.

| output_metric_name
|   Type: unicode
|   The Fields[name] value of the metric messages that the GSE plugin emits.

| interval
|   Type: integer
|   The interval (in seconds) at which the GSE plugin emits its metric messages.

| warm_up_period
|   Type: integer
|   The number of seconds after a (re)start that the GSE plugin will wait
    before emitting its metric messages.

| alerting
|   Type: string (one of 'disabled', 'enabled' or 'enabled_with_notification').
|   The alerting configuration of the service clusters.

| clusters
|   Type: list
|   The list of service clusters that the plugin handles. See
    :ref:`service_cluster` for details.

.. _service_cluster:

Service cluster definition
++++++++++++++++++++++++++

The following example shows the service clusters definition::

  gse_cluster_service:
    [...]
    clusters:
      nova-api:
        members:
          - backends
          - endpoint
          - http_errors
        group_by: member
        policy: highest_severity

Where

| members
|   Type: list
|   The list of cluster members.
    The AFD messages that are associated with the cluster when the
    ``cluster_field`` value is equal to the cluster name and the
    ``member_field`` value is in this list.

| group_by
|   Type: Enum(member, hostname)
|   This parameter defines how the incoming AFD metrics are aggregated.
|
|     member:
|       aggregation by member, irrespective of the host that emitted the AFD
|       metric. This setting is typically used for AFD metrics that are not
|       host-centric.
|
|     hostname:
|       aggregation by hostname then by member.
|       This setting is typically used for AFD metrics that are host-centric,
|       such as those working on the file system or CPU usage metrics.

| policy:
|   Type: unicode
|   The policy to use for computing the service cluster status.
    See :ref:`gse_policies` for details.

A closer look into the example above defines that the Service Cluster GSE
plugin resulting from those rules will emit a *gse_service_cluster_metric*
message every 10 seconds to report the current status of the *nova-api*
cluster. This status is computed using the *afd_service_metric* metric for
which Fields[service] is 'nova-api' and Fields[source] is one of 'backends',
'endpoint', or 'http_errors'. The 'nova-api' cluster's status is computed using
the 'highest_severity' policy, which means that it will be equal to the 'worst'
status across all members.

.. _gse_cluster_node:

Node cluster aggregation rules
++++++++++++++++++++++++++++++

The node cluster aggregation rules are used to designate the members of a node
cluster along with the AFD metrics that must be taken into account to derive
a health status for the node cluster. The following is an example of the node
cluster aggregation rules::

  gse_cluster_node:
    input_message_types:
      - afd_node_metric
    aggregator_flag: true
    # the field in the input messages to identify the cluster
    cluster_field: node_role
    # the field in the input messages to identify the cluster's member
    member_field: source
    output_message_type: gse_node_cluster_metric
    output_metric_name: cluster_node_status
    interval: 10
    warm_up_period: 80
    alerting: enabled_with_notification
    clusters:
      controller:
        policy: majority_of_members
        group_by: hostname
        members:
          - cpu
          - root-fs
          - log-fs

Where

| input_message_types
|   Type: list
|   The type(s) of AFD metric messages consumed by the GSE plugin.

| aggregator_flag
|   Type: boolean
|   Whether or not the input messages are received from the upstream collectors.
    This is true for the Service and Node Cluster plugins and false for the
    Global Cluster plugin.

| cluster_field
|   Type: unicode
|   The field in the input message used by the GSE plugin to associate the
    AFD metrics to the clusters.

| member_field
|   Type: unicode
|   The field in the input message used by the GSE plugin to identify the
    cluster members.

| output_message_type
|   Type: unicode
|   The type of metric messages emitted by the GSE plugin.

| output_metric_name
|   Type: unicode
|   The Fields[name] value of the metric messages that the GSE plugin emits.

| interval
|   Type: integer
|   The interval (in seconds) at which the GSE plugin emits its metric messages.

| warm_up_period
|   Type: integer
|   The number of seconds after a (re)start that the GSE plugin will wait
    before emitting its metric messages.

| alerting
|   Type: string (one of 'disabled', 'enabled' or 'enabled_with_notification').
|   The alerting configuration of the node clusters.

| clusters
|   Type: list
|   The list of node clusters that the plugin handles. See
    :ref:`node_cluster` for details.

.. _node_cluster:

Node cluster definition
+++++++++++++++++++++++

The following example shows the node clusters definition::

  gse_cluster_node:
    [...]
    clusters:
      controller:
        policy: majority_of_members
        group_by: hostname
        members:
          - cpu
          - root-fs
          - log-fs

Where

| members
|   Type: list
|   The list of cluster members.
    The AFD messages are associated to the cluster when the ``cluster_field``
    value is equal to the cluster name and the ``member_field`` value is in
    this list.

| group_by
|   Type: Enum(member, hostname)
|   This parameter defines how the incoming AFD metrics are aggregated.
|
|     member:
|       aggregation by member, irrespective of the host that emitted the AFD
|       metric. This setting is typically used for AFD metrics that are not
|       host-centric.
|
|     hostname:
|       aggregation by hostname then by member.
|       This setting is typically used for AFD metrics that are host-centric,
|       such as those working on the file system or CPU usage metrics.

| policy:
|   Type: unicode
|   The policy to use for computing the node cluster status.
    See :ref:`gse_policies` for details.

A closer look into the example above defines that the Node Cluster GSE plugin
resulting from those rules will emit a *gse_node_cluster_metric* message every
10 seconds to report the current status of the *controller* cluster. This
status is computed using the *afd_node_metric* metric for which
Fields[node_role] is 'controller' and Fields[source] is one of 'cpu',
'root-fs' or 'log-fs'. The 'controller' cluster's status is computed using the 'majority_of_members' policy which means that it will be equal to the 'majority'
status across all members.

.. _gse_cluster_global:

Top-level cluster aggregation rules
+++++++++++++++++++++++++++++++++++

The top-level aggregation rules aggregate GSE metrics from the Service
Cluster GSE Plugin and the Node Cluster GSE Plugin. This is the last
aggregation stage that issues health status for the top-level clusters.
A top-level cluster is a logical construct of service and node clustering.
By default, we define that the health status of Nova, as a top-level cluster,
depends on the health status of several service clusters related to Nova and
the health status of the 'controller' and 'compute' node clusters. But it can
be anything. For example, you can define a 'control-plane' top-level cluster
that would exclude the health status of the 'compute' node cluster if required.
The top-level cluster aggregation rules are used to designate the node
clusters and service clusters members of a top-level cluster along with the
GSE metrics that must be taken into account to derive a health status for the
top-level cluster. The following is an example of a top-level cluster
aggregation rules::

  gse_cluster_global:
    input_message_types:
      - gse_service_cluster_metric
      - gse_node_cluster_metric
    aggregator_flag: false
    # the field in the input messages to identify the cluster's member
    member_field: cluster_name
    output_message_type: gse_cluster_metric
    output_metric_name: cluster_status
    interval: 10
    warm_up_period: 30
    clusters:
      nova:
        policy: highest_severity
        group_by: member
        members:
          - nova-logs
          - nova-api
          - nova-metadata-api
          - nova-scheduler
          - nova-compute
          - nova-conductor
          - nova-cert
          - nova-consoleauth
          - nova-novncproxy-websocket
          - controller
          - compute
        hints:
          - cinder
          - glance
          - keystone
          - neutron
          - mysql
          - rabbitmq

Where

| input_message_types
|   Type: list
|   The type(s) of GSE  metric messages consumed by the GSE plugin.

| aggregator_flag
|   Type: boolean
    This is always false for the Global Cluster plugin.

| member_field
|   Type: unicode
|   The field in the input message used by the GSE plugin to identify the
    cluster members.

| output_message_type
|   Type: unicode
|   The type of metric messages emitted by the GSE plugin.

| output_metric_name
|   Type: unicode
|   The Fields[name] value of the metric messages that the GSE plugin emits.

| interval
|   Type: integer
|   The interval (in seconds) at which the GSE plugin emits its metric messages.

| warm_up_period
|   Type: integer
|   The number of seconds after a (re)start that the GSE plugin will wait
    before emitting its metric messages.

| clusters
|   Type: list
|   The list of node clusters and service clusters that the plugin handles. See
    :ref:`global_cluster` for details.

.. _global_cluster:

Top-level cluster definition
++++++++++++++++++++++++++++

The following example shows the top-level clusters definition::

  gse_cluster_global:
    [...]
    clusters:
      nova:
        policy: highest_severity
        group_by: member
        members:
          - nova-logs
          - nova-api
          - nova-metadata-api
          - nova-scheduler
          - nova-compute
          - nova-conductor
          - nova-cert
          - nova-consoleauth
          - nova-novncproxy-websocket
          - controller
          - compute
        hints:
          - cinder
          - glance
          - keystone
          - neutron
          - mysql
          - rabbitmq

Where

| members
|   Type: list
|   The list of cluster members.
|   The GSE messages are associated to the cluster when the ``member_field``
|   value (``cluster_name``), is on this list.

| hints
|   Type: list
|   The list of clusters that are indirectly associated with the top-level
|   cluster. The GSE messages are indirectly associated to the cluster when
|   the ``member_field`` value (``cluster_name``) is on this list. This means
|   that they are not used to derive the health status of the top-level
|   cluster but as 'hints' for root cause analysis.

| group_by
|   Type: Enum(member, hostname)
|   This parameter defines how the incoming GSE metrics are aggregated.
|   In the case of the top-level cluster definition, it is always by member.

| policy:
|   Type: unicode
|   The policy to use for computing the top-level cluster status.
    See :ref:`gse_policies` for details.

.. _puppet_apply:

Apply your configuration changes
--------------------------------

Once you have edited and saved your changes in
``/etc/hiera/override/alarming.yaml`` and / or
``/etc/hiera/override/gse_filters.yaml``,
apply the following Puppet manifest on all the nodes of your OpenStack
environment **including the node(s) where Nagios is installed**
for the changes to take effect::

  # puppet apply --modulepath=/etc/fuel/plugins/lma_collector-<version>/puppet/modules:\
      /etc/puppet/modules \
      /etc/fuel/plugins/lma_collector-<version>/puppet/manifests/configure_afd_filters.pp

If you have also deployed *lma_infrastructure_alerting" plugin, Nagios must be reconfigured as well
by running the following commands on all the nodes with the *lma_infrastructure_alerting* role::

  # rm -f /etc/nagios3/conf.d/lma_* && puppet apply \
       --modulepath=/etc/fuel/plugins/lma_infrastructure_alerting-<version>/puppet/modules:\
      /etc/puppet/modules \
      /etc/fuel/plugins/lma_infrastructure_alerting-<version>/puppet/manifests/nagios.pp
