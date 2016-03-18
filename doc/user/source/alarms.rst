.. _alarm_guide:

Alarms Configuration Guide
============================

.. _alarm_overview:

Overview
--------

The process of running alarms in LMA is not centralized
(as it is often the case in conventional monitoring systems)
but distributed across all the Collectors.

Each Collector is individually responsible for monitoring the
resources and the services that are deployed on the node and for reporting
any anomaly or fault it may have detected to the *Aggregator*.

The anomaly and fault detection logic in LMA is designed
more like an "Expert System" in that the Collector and the Aggregator use *facts*
and *rules* that are executed within the Heka's stream processing pipeline.

The *facts* are the messages ingested by the Collector
into the Heka pipeline.
The rules are either threshold monitoring alarms or aggregation
and correlation rules. Both are declaratively defined in YAML(tm) files
that can be modified.
Those rules are executed by a collection of Heka filter plugins written in Lua
organised according to a configurable processing workflow.

These plugins are called *AFD plugins* for Anomaly and Fault Detection plugins
and *GSE plugins* for Global Status Evaluation plugins.

Both the AFD and GSE plugins create metrics called respectively the *AFD metrics*
and the *GSE metrics*.


.. figure:: ../../images/AFD_and_GSE_message_flow.*
   :width: 800
   :alt: Message flow for the AFD and GSE metrics
   :align: center

   Message flow for the AFD and GSE metrics

The *AFD metrics* contain information about the health status of a
resource such as a device, a system component like a filesystem, or service
like an API endpoint, at the node level.
Then, those *AFD metrics* are sent on a regular basis by each Collector
to the Aggregator where they can be aggregated and correlated hence the
name 'aggregator'.

The *GSE metrics* contain information about the health status
of a service cluster, such as the Nova API endpoints cluster, or the RabbitMQ
cluster as well as the clusters of nodes, like the Compute cluster or
Controller cluster.
The health status of a cluster is inferred by the GSE plugins using
aggregation and correlation rules and facts contained in the
*AFD metrics* it received from the Collectors.

In the current version of the LMA Toolchain, there are three :ref:`gse_plugins`:

* The Service Cluster GSE which receives metrics from the AFD plugins monitoring
  the services and emits health status for the clusters of services (nova-api, nova-scheduler and so forth).
* The Node Cluster GSE which receives metrics from the AFD plugins monitoring
  the system and emits health status for the clusters of nodes (controllers, computes and so forth).
* The Global Cluster GSE which receives metrics from the two other GSE plugins
  and emits health status for the top-level clusters (Nova, MySQL and so forth).

The meaning for each health status is as follow:

* **Down**: One or several primary functions of a cluster has failed or is failing.
  For example, the API service for Nova or Cinder isn't accessible.
* **Critical**: One or several primary functions of a
  cluster are severely degraded. The quality
  of service delivered to the end-user should be severely
  impacted.
* **Warning**: One or several primary functions of the
  cluster are slightly degraded. The quality
  of service delivered to the end-user should be slightly
  impacted.
* **Unknown**: There is not enough data to infer the actual
  health state of the cluster.
* **Okay**: None of the above was found to be true.

The *AFD and GSE metrics* are also consumed by other groups
of Heka plugins called the *Persisters*.

* A *Persister* for InfluxDB turns the *GSE metric*
  messages into InfluxDB data-points and Grafana annotations. They
  are displayed in Grafana dashboards to represent the
  health status of the OpenStack services and clusters.
* A *Persister* for Elasticsearch turns the *AFD metrics*
  messages into AFD events which are indexed in Elasticsearch to
  be able to search and display the faults and anomalies that occured
  in the OpenStack environment.
* A *Persister* for Nagios turns the *GSE metrics*
  messages into passive checks that are sent to Nagios which in turn
  will send alert notifications when there is a change of state for
  the services and clusters being monitored.

The *AFD metrics* and *GSE metrics* are new types of metrics introduced
in LMA v 0.8. They contain detailed information about the entities
being monitored.
Please refer to the `Metrics section of the Developer Guide
<http://fuel-plugin-lma-collector.readthedocs.org/en/latest/dev/metrics.html>`_
for further information about the structure of those messages.

Any backend system that has a *Persister* plugged
into the Heka pipeline of the Aggregator can consume those metrics.
The idea is to feed those systems with rich operational
insights about how OpenStack is operating at scale.

.. _alarm_configuration:

Alarm Configuration
-------------------

The LMA Toolchain comes out-of-the-box with predefined alarm and correlation
rules. We have tried to make the alarm rules comprehensive and relevant enough
to cover the most common use cases, but it is possible that your mileage varies
depending on the specifics of your environment and monitoring requirements.
It is obviously possible to modify the alarm rules or even create new ones.
In this case, you will be required to modify the alarm rules configuration
file and reapply the Puppet module that will turn the alarm rules into Lua code
on each of the nodes you want the change to take effect. This procedure is
explained below but first you need to know how the alarm rule structure is
defined.

.. _alarm_structure:

Alarm Structure
~~~~~~~~~~~~~~~

An alarm rule is defined declaratively using the YAML syntax
as shown in the example below::

    name: 'fs-warning'
    description: 'Filesystem free space is low'
    severity: 'warning'
    enabled: 'true'
    trigger:
      rules:
        - metric: fs_space_percent_free
          fields:
            fs: '*'
          relational_operator: '<'
          threshold: 5
          window: 60
          periods: 0
          function: min

Where:
~~~~~~

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
|    The conjonction relation for the alarm rules.

| metric
|    Type: unicode
|    The name of the metric

| value
|   Type: unicode
|   The value of the metric

| fields
|   Type: list
|   List of field name / value pairs (a.k.a dimensions) used to select
    a particular device for the metric such as a network interface name or file
    system mount point. If value is specified as an empty string (""), then the rule
    is applied to all the aggregated values for the specified field name. For example
    the file system mount point.
    If value is specified as the '*' wildcard character,
    then the rule is applied to each of the metrics matching the metric name and field name.
    For example, the alarm definition sample given above would run the rule
    for each of the file system mount points associated with the *fs_space_percent_free* metric.

| window
|   Type: integer
|   The in memory time-series analysis window in seconds

| periods
|   Type: integer
|   The number of prior time-series analysis window to compare the window with (this is
|   not implemented yet)

.. _alarm_functions:

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
|       The 'roc' function detects a significant rate
        of change when comparing current metrics values with historical data.
        To achieve this, it computes the average of the values in the current window,
        and the average of the values in the window before the current window and
        compare the difference against the standard deviation of the
        historical window. The function returns true if the difference
        exceeds the standard deviation multiplied by the 'threshold' value.
        This function uses the rate of change algorithm already available in the
        anomaly detection module of Heka. It can only be applied on normal
        distributions.
        With an alarm rule using the 'roc' function, the 'window' parameter
        specifies the duration in seconds of the current window and the 'periods'
        parameter specifies the number of windows used for the historical data.
        You need at least one period and so, the 'periods' parameter must not be zero.
        If you choose a period of 'p', the function will compute the rate of
        change using an historical data window of ('p' * window) seconds.
        For example, if you specify in the alarm rule:
|
|           window = 60
|           periods = 3
|           threshold = 1.5
|
|       The function will store in a circular buffer the value of the metrics
        received during the last 300 seconds (5 minutes) where:
|
|           Current window (CW) = 60 sec
|           Previous window (PW) = 60 sec
|           Historical window (HW) = 180 sec
|
|       And apply the following formula:
|
|            abs(avg(CW) - avg(PW)) > std(HW) * 1.5 ? true : false

|     mww:
|       returns the result (true, false) of the Mann-Whitney-Wilcoxon test function
|       of Heka that can be used only with normal distributions (not implemented yet)
|     mww-nonparametric:
|       returns the result (true, false) of the Mann-Whitney-Wilcoxon
|       test function of Heka that can be used with non-normal distributions (not implemented yet)
|     diff:
|       returns the difference between the last value and the first value of all the values

| threshold
|   Type: float
|   The threshold of the alarm rule


How to modify an alarm?
~~~~~~~~~~~~~~~~~~~~~~~

To modify an alarm, you need to edit the */etc/hiera/override/alarming.yaml*
file. This file has three different sections:

* The first section contains a list of alarms.
* The second section defines the mapping between the internal definition of
  a cluster and one or several Fuel roles.
  The definition of a cluster is abstrat. It can be mapped to any Fuel role(s).
  In the example below, we define three clusters for:

    * controller,
    * compute,
    * and storage

* The third section defines how the alarms are assigned to clusters.
  In the example below, the *controller* cluster is assigned to four alarms:

    * Two alarms ['cpu-critical-controller', 'cpu-warning-controller'] grouped as *system* alarms.
    * Two alarms ['fs-critical', 'fs-warning'] grouped as *fs* (file system) alarms.

Note:
  The alarm groups is a mere implementaton artifact (although
  it has some practicall usefulness) that is used to divide the workload
  across several Lua plugins. Since the Lua plugins
  runtime is sandboxed within Heka, it is preferable to run
  smaller sets of alarms in different plugins rather than a large set
  of alarms in a single plugin. This is to avoid having plugins shut down
  by Heka because they use too much CPU or memory.
  Furthermore, the alarm groups are used to identify what we
  call a *source*. A *source* is defined by a tuple which includes the name of
  the cluster and the name of the alarm group.
  For example the tuple ['controller', 'system'] identifies a *source*.
  The tuple ['controller', 'fs'] identifies another *source*.
  The interesting thing about the *source* is that it is used by the
  *GSE Plugins* to find out whether it has received enough data
  (from its 'known' *sources*) to issue a health status or not.
  If it doesn't, then the *GSE Plugin* will issue a *GSE Metric* with an
  *Unknown* health status when it has reached the end of the
  *ticker interval* period.
  By default, the *ticker interval* for the GSE Plugins is set to
  10 seconds. This practically means that every 10 seconds, a GSE Plugin
  is compelled to send a *GSE Metric* regardless of the metrics
  it has received from the upstream *GSE Plugins* and/or *AFD Plugins*.

Here is an example of the definition of an alarm and how
that alarm is assigned to a cluster::

    lma_collector:
        #
        # The alarms list
        #
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

        [Skip....]

        #
        # Cluster name to roles mapping section
        #
      node_cluster_roles:
        controller: ['primary-controller', 'controller']
        compute: ['compute']
        storage: ['cinder', 'ceph-osd']

        #
        # Cluster name to alarms assignement section
        #
      node_cluster_alarms:
        controller:
          system: ['cpu-critical-controller', 'cpu-warning-controller']
          fs: ['fs-critical', 'fs-warning']

In this example, you can see that the alarm *cpu-critical-controller* is
assigned to the *controller* cluster (or in other words) to the nodes assigned
to the *primary-controller* or *controller* roles.

This alarm tells the system that any node associated with the *controller*
cluster is claimed to be critical (severity: 'critical') if any of the rules in
the alarm evaluates to true.

The first rule says that the alarm evaluates to true if
the metric *cpu_idle* has been in average (function: avg) below or equal
(relational_operator: <=) to 5 (this metric is expressed in percentage) for the
last 5 minutes (window: 120)

Or (logical_operator: 'or')

if the metric *cpu_wait* has been in average (function: avg) superior or equal
(relational_operator: >=) to 35 (this metric is expressed in percentage) for the
last 5 minutes (window: 120)

Once you have edited and saved the */etc/hiera/override/alarming.yaml* file, you
need to re-apply the Puppet module::

    # puppet apply --modulepath=/etc/fuel/plugins/lma_collector-0.9/puppet/modules/ \
    /etc/fuel/plugins/lma_collector-0.9/puppet/manifests/configure_afd_filters.pp

This will restart the LMA Collector with your change.

.. _gse_plugins:

GSE configuration
-----------------

The LMA toolchain comes with a predefined configuration for the GSE plugins. As
for the alarms, it is possible to modify this configuration.

The GSE plugins are defined declaratively in the
*/etc/hiera/override/gse_filters.yaml* file. By default, that file specifies
three kinds of GSE plugins:

* *gse_cluster_service* for the Service Cluster GSE which evaluates the status
  of the service clusters.

* *gse_cluster_node* for the Node Cluster GSE which evaluates the status of the
  node clusters.

* *gse_cluster_global* for the Global Cluster GSE  which evaluates the status
  of the global clusters.

The structure of a GSE plugin declarative definition is described below::

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
    clusters:
      nova-api:
        policy: highest_severity
        group_by: member
        members:
          - backends
          - endpoint
          - http_errors
      [...]

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
    AFD/GSE metrics to the clusters.

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
|   The list of clusters that the plugin manages. See
    :ref:`cluster_definitions` for details.

.. _cluster_definitions:

Cluster definition
~~~~~~~~~~~~~~~~~~

The GSE clusters are defined as shown in the example below::

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

    [...]

Where

| members
|   Type: list
|   The list of cluster members.
    The AFD/GSE messages are associated to the cluster when the *cluster_field*
    value is equal to the cluster name and the *member_field* value is in this
    list.

| group_by
|   Type: Enum(member, hostname)
|   This parameter defines how the incoming AFD metrics are aggregated.
|
|     member:
|       aggregation by member, irrespective of the host that emitted the AFD metric.
|       This setting is typically used for AFD metrics that are not host-centric.
|
|     hostname:
|       aggregation by hostname then by member.
|       This setting is typically used for AFD metrics that are host-centric such as
|       those working on filesystem or CPU usage metrics.

| policy:
|   Type: unicode
|   The policy to use for computing the cluster status. See :ref:`cluster_policies`
    for details.

If we look more closely at the example above, it defines that the Service
Cluster GSE plugin will emit a *gse_service_cluster_metric* message every 10
seconds that will report the current status of the *nova-api* cluster. This
status is computed using the  *afd_service_metric* metrics for which
Fields[service] is 'nova-api' and Fields[source] is one of 'backends',
'endpoint' or 'http_errors'. The 'nova-api' cluster's status is computed using
the 'highest_severity' policy which means that it will be equal to the 'worst'
status across all members.

.. _cluster_policies:

Cluster policies
~~~~~~~~~~~~~~~~

The correlation logic implemented by the GSE plugins is policy-based.
The cluster policies define how the GSE plugins infer the health status of a
cluster.

By default, two policies are defined:

* *highest_severity*, it defines that the cluster's status depends on the
  member with the highest severity, typically used for a cluster of services.
* *majority_of_members*, it defines that the cluster is healthy as long as
  (N+1)/2 members of the cluster are healthy. This is typically used for
  clusters managed by Pacemaker.

The GSE policies are defined declaratively in the */etc/hiera/override/gse_filters.yaml*
file at the *gse_policies* entry.

A policy consists of a list of rules which are evaluated against the
current status of the cluster's members. When one of the rules matches, the
cluster's status gets the value associated with the rule and the evaluation
stops here. The last rule of the list is usually a catch-all rule that
defines the default status in case none of the previous rules could be matched.

A policy rule is defined as shown in the example below::

   # The following rule definition reads as: "the cluster's status is critical
   # if more than 50% of its members are either down or criticial"
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
|    The conjonction relation for the condition rules

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

Lets now take a more detailed look at the policy called *highest_severity*::

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

The policy definition reads as:

* The status of the cluster is *Down* if the status of at least one cluster's member is *Down*.

* Otherwise the status of the cluster is *Critical* if the status of at least one cluster's member is *Critical*.

* Otherwise the status of the cluster is *Warning* if the status of at least one cluster's member is *Warning*.

* Otherwise the status of the cluster is *Okay* if the status of at least one cluster's entity is *Okay*.

* Otherwise the status of the cluster is *Unknown*.
