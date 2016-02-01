.. _releases:

Release Notes
=============

Version 0.9.0
-------------

* Collect libvirt metrics on compute nodes.
* Add support for the 'roc' (rate of change) test for the alarm functions.
* Fixes several `critical bugs
  <https://bugs.launchpad.net/lma-toolchain/+bugs?field.searchtext=&orderby=-importance&field.status%3Alist=FIXCOMMITTED&field.importance%3Alist=CRITICAL&field.importance%3Alist=HIGH&assignee_option=any&field.assignee=&field.bug_reporter=&field.bug_commenter=&field.subscriber=&field.structural_subscriber=&field.milestone%3Alist=74689&field.tag=&field.tags_combinator=ANY&field.has_cve.used=&field.omit_dupes.used=&field.omit_dupes=on&field.affects_me.used=&field.has_patch.used=&field.has_branches.used=&field.has_branches=on&field.has_no_branches.used=&field.has_no_branches=on&field.has_blueprints.used=&field.has_blueprints=on&field.has_no_blueprints.used=&field.has_no_blueprints=on&search=Search>`_.

Version 0.8.0
-------------

* Support for alerting in two different modes:

  * Email notifications.

  * Integration with Nagios.

* Upgrade to InfluxDB 0.9.5.

* Upgrade to Grafana 2.5.

* Management of the LMA collector service by Pacemaker on the controller nodes for improved reliability.

* Monitoring of the LMA toolchain components (self-monitoring).

* Support for configurable alarm rules in the Collector.


Version 0.7.0
-------------

* Initial release of the plugin. This is a beta version.
