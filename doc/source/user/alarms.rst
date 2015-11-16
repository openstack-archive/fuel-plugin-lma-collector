.. _alarm_guide:

Alarms Configuration Guide
============================

.. _alarm_overview:

Overview
--------

The process of running alarms in LMA is not centralized
(like it is often the case in conventional monitoring systems)
but distributed across all the Collectors.

Each Collector is individuallly responsible for monitoring the
resources and the services that are deployed on the node and for reporting
any anomaly or fault it may have detected to the *Aggregator*.

The anomaly and fault detection logic in LMA is designed
more like an "Expert System" in that the Collector and the Aggregator use *facts*
and *rules* that are executed within the Heka's stream processing pipeline.

The *facts* are the messages ingested by the Collector
into the Heka pipeline.
The rules are either threshold monitoring alarms or aggregation
and correlation rules. Both are declaratively defined in YAML(tm) files
that you can modify.
Those rules are executed by a collection of Heka filter plugins written in Lua
that are organised according to a configurable processing workflow.

We call these plugins the *AFD plugins* for Anomaly and Fault Detection plugins
and the *GSE plugins* for Global Status Evaluation plugins.

Both the AFD and GSE plugins in turn create metrics called the *AFD metrics*
and the *GSE metrics* respectively.


.. figure:: ../../images/AFD_and_GSE_message_flow.*
   :width: 800
   :alt: Message flow for the AFD and GSE metrics
   :align: center

   Message flow for the AFD and GSE metrics

The *AFD metrics* contain information about the health status of a
resource like a device, a system component like a filesystem, or service
like an API endpoint, at the node level.
Then, those *AFD metrics* are sent on a regular basis by each Collector
to the Aggregator where they can be aggregated and correlated hence the
name of aggregator.

The *GSE metrics* contain information about the health status
of a service cluster, like the Nova API endpoints cluster, or the RabbitMQ
cluster as well as the clusters of nodes, like the Compute cluster or
Controller cluster.
The health status of a cluster is inferred by the GSE plugins using
aggregation and correlation rules and facts contained in the
*AFD metrics* it receives from the Collectors.

In the current version of the LMA toolchain, 3 GSE plugins are configured:

* The Service Cluster GSE which receives metrics from the AFD plugins monitoring the services and emits health status for the clusters of services (nova-api, nova-scheduler and so on).
* The Node Cluster GSE which receives metrics from the AFD plugins monitoring the system and emits health status for the clusters of nodes (controllers, computes and so on).
* The Global Cluster GSE which receives metrics from the 2 other GSE plugins and emits health status for the top-level clusters (Nova, MySQL and so on).

The meaning associated with a health status is the following:

* **Down**: One or several primary functions of a cluster are failed. For example,
  the API service for Nova or Cinder isn't accessible.
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
of Heka plugins we call the *Persisters*.

* There is a *Persister* for InfluxDB which turns the *GSE metric*
  messages into InfluxDB data-points and Grafana annotations. They
  are displayed in Grafana dashboards to represent the
  health status of the OpenStack services and clusters.
* There is a *Persister* for Elasticsearch which turns the *AFD metrics*
  messages into AFD events which are indexed in Elasticsearch to
  be able to search and display the faults and anomalies that occured
  in the OpenStack environment.
* There is a *Persister* for Nagios which turns the *GSE metrics*
  messages into passive checks that are sent to Nagios which in turn
  will send alert notifications when there is a change of state for
  the services and clusters being monitored.

The *AFD metrics* and *GSE metrics* are new types of metrics introduced
in LMA v 0.8. They contain detailed information about the entities
being monitored.
Please refer to the `Metrics section of the Developer Guide
<http://fuel-plugin-lma-collector.readthedocs.org/en/latest/dev/metrics.html>`_.
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
In this case, you will be required to modify the alarmn rules configuration
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
    is applied to all the aggregated values for the specified field name like for example
    the file system mount point.
    If value is specified as the ‘*’ wildcard character,
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

| function
|   Type: enum(‘last’ | ‘min’ | ‘max’ | ‘sum’ | ‘count’ | ‘avg’ | ‘median’ | ‘mode’ | ‘roc’ | ‘mww’ | ‘mww_nonparametric’)
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
|       returns the result (true, false) of the rate of change test function of
|       Heka (not implemented yet)
|     mww:
|       returns the result (true, false) of the Mann-Whitney-Wilcoxon test function
|       of Heka that can be used only with normal distributions (not implemented yet)
|     mww-nonparametric:
|       returns the result (true, false) of the Mann-Whitney-Wilcoxon
|       test function of Heka that can be used with non-normal distributions (not implemented yet)
|     diff:
|       returns [TBC]

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

* The third section defines how the alarms are assingned to clusters.
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

This alarm tells the system that any node that is associated with the *controller*
cluster is claimed to be critical (severity: 'critical') if any of the rules in
the alarm evaluates to true.

The first rule says that the alarm evaluates to true if
the metric *cpu_idle* has been in average (function: avg) below or equal
(relational_operator: <=) to 5 (this metric is expressed in percentage) for the
last 5 minutes (window: 120)

Or (logical_operator: 'or')

if the metric *cpu_wait* has been in average (function: avg) superiror or equal
(relational_operator: >=) to 35 (this metric is expressed in percentage) for the
last 5 minutes (window: 120)

Once you have edited and saved the */etc/hiera/override/alarming.yaml* file, you
need to re-apply the Puppet module::

    # puppet apply --modulepath=/etc/fuel/plugins/lma_collector-0.8/puppet/modules/ \
    /etc/fuel/plugins/lma_collector-0.8/puppet/manifests/configure_afd_filters.pp

This will restart the LMA Collector with your change.

Cluster policies
----------------

The GSE plugins are driven by policies that describe how the the GSE plugin
determines the cluster's health status.

By default, 2 policies are defined:

* *highest_severity*, it defines that the cluster's status depends on the
  member with the highest severity, typically used for a cluster of services.
* *majority_of_members*, it is typically used for clusters managed by
  Pacemaker with the no-quorum-policy set to 'stop'.

The GSE policies are defined declaratively in the */etc/hiera/override/gse_filters.yaml*
file at the *gse_policies* entry.

A policy consists of a list of rules which are evaluated against the
current status of the cluster's members. When one of the rules matches, the
cluster's status gets the value associated with the rule and the evaluation
stops here. The last rule of the list is usually a catch-all rule that
defines the default status in case no other rule matched.

The declaration of a policy rule is similar to an alarm rule except that:

#. There are no 'metric', 'window' and 'period' parameters.

#. There are only 2 supported functions:

  * 'count' which returns the *number of members* that match the passed value(s).

  * 'percent' which returns the *percentage of members* that match the passed value(s).

For instance, the following rule definition reads as "the cluster's status is
critical if more than 50% of its members are either down or criticial"::

   - status: critical
     trigger:
       logical_operator: or
       rules:
         - function: percent
           arguments: [ down, critical ]
           relational_operator: '>'
           threshold: 50

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

* Otherwise the status of the cluster is *Critical* if the status of at least one cluster's member is *Crtical*.

* Otherwise the status of the cluster is *Warning* if the status of at least one cluster's member is *Warning*.

* Otherwise the status of the cluster is *Okay* if the status of at least one cluster's entity is *Okay*.

* Otherwise the status of the cluster is *Unknown*.

The GSE policies are defined declaratively in the */etc/hiera/override/gse_filters.yaml*
file at the *gse_policies* entry.
