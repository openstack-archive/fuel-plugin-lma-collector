..
 This work is licensed under a Creative Commons Attribution 3.0 Unported
 License.

 http://creativecommons.org/licenses/by/3.0/legalcode

==============================================================
Fuel plugin for the Logging, Monitoring and Alerting collector
==============================================================

https://blueprints.launchpad.net/fuel/+spec/lma-collector-plugin

The LMA (Logging, Monitoring & Alerting) collector is a service running on each
OpenStack node that collects metrics, logs and notifications. This data can be
sent to ElasticSearch [#]_ and/or InfluxDB [#]_ backends for diagnostic and
troubleshooting purposes.

Problem description
===================

There is currently no comprehensive set of tools integrated with Fuel for
monitoring, diagnosing and troubleshooting the deployed OpenStack environments.

The LMA collector aims at addressing the following use cases:

* Send logs and notifications to ElasticSearch so operators can more easily
  troubleshoot issues.

* Send metrics to InfluxDB so operators can monitor and diagnose the usage
  of resources This will cover:

  + Operating system metrics (CPU, RAM, ...).

  + Service metrics (MySQL, RabbitMQ, ...).

  + OpenStack metrics (for instance, the number of free/used vCPUs)

  + Metrics extracted from logs and notifications (for instance, the HTTP
    response times).

Proposed change
===============

Implement a Fuel plugin that will install and configure the LMA collector
service on all the OpenStack nodes.

Alternatives
------------

It might have been implemented as part of Fuel core but we decided to make it
as a plugin for several reasons:

* This isn't something that all operators may want to deploy.

* Any new additional functionality makes the project's testing more difficult,
  which is an additional risk for the Fuel release.

* Ideally, this effort may be of interest for non-Fuel based deployments too.

We could also have leveraged the Zabbix implementation already available since
Fuel 5.1 but Zabbix doesn't cover the same use cases:

* It isn't a log management solution.

* It isn't particularly suited for storing timeseries.


Data model impact
-----------------

None

REST API impact
---------------

None

Upgrade impact
--------------

None

Security impact
---------------

None

Notifications impact
--------------------

None

Other end user impact
---------------------

None

Performance Impact
------------------

Since the collector service runs as a daemon on all the nodes, it will consume
resources from the nodes. However the components it is built upon have a small
footprint both in terms of CPU usage and memory.

Other deployer impact
---------------------

The deployer will have to run an ElasticSearch cluster and/or an InfluxDB
cluster to store the collected data. Eventually these requirements will be
addressed by additional Fuel plugins once the custom role feature [#]_ gets
available.

Developer impact
----------------

None

Implementation
==============

Assignee(s)
-----------

Primary assignee:
  Simon Pasquier <spasquier@mirantis.com> (feature lead, developer)

Other contributors:
  Guillaume Thouvenin <gthouvenin@mirantis.com> (developer)
  Swann Croiset <scroiset@mirantis.com> (developer)
  Irina Povolotskaya <ipovolotskaya@mirantis.com> (tech writer)


Work Items
----------

* Implement the Fuel plugin.

* Implement the Puppet manifests.

* Testing.

* Write the documentation.

Dependencies
============

* Fuel 6.0 and higher.

Testing
=======

* Prepare a test plan.

* Test the plugin by deploying environments with all Fuel deployment modes.

* Integration tests with ElasticSearch and InfluxDB backends.

Documentation Impact
====================

* Deployment Guide (how to install the storage backends, how to prepare an
  environment for installation, how to install the plugin, how to deploy an
  OpenStack environment with the plugin).

* User Guide (which features the plugin provides, how to use them in the
  deployed OpenStack environment).

* Test Plan.

* Test Report.

References
==========

.. [#] http://www.elasticsearch.org/

.. [#] http://www.influxdb.com/

.. [#] https://blueprints.launchpad.net/fuel/+spec/role-as-a-plugin
