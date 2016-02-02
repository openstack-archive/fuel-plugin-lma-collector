.. _system_testing:

System testing
==============

.. _install_lma_plugins:

Install the plugins
-------------------

.. include:: tests/install.rst

.. _deploy_lma_plugins:

Deploy an environment with the plugins
--------------------------------------

.. include:: tests/deploy.rst

.. _add_remove_controller:

Add/remove controller nodes in existing environment
---------------------------------------------------

.. include:: tests/scale_controller.rst

.. _add_remove_compute:

Add/remove compute nodes in existing environment
------------------------------------------------

.. include:: tests/scale_compute.rst

.. _uninstall_plugins_with_env:

Uninstall the plugins with deployed environment
-----------------------------------------------

.. include:: tests/uninstall_plugins_with_env.rst

.. _uninstall_plugins:

Uninstall the plugins
---------------------

.. include:: tests/uninstall_plugins.rst

.. _functional_testing:

Functional testing
==================

.. _deploy_ha_mode: 

Deploy plugins in HA mode
-------------------------

.. include:: tests/deploy_ha_mode.rst

.. _scale_influx:

Add/remove influxdb nodes in existing environment
-------------------------------------------------

.. include:: tests/scale_influx.rst

.. _scale_elasticsearch:

Add/remove elasticsearch nodes in existing environment
------------------------------------------------------

.. include:: tests/scale_elasticsearch.rst

.. _scale_infrastructure_alerting:

Add/remove infrastructure alerting nodes in existing environment
----------------------------------------------------------------

.. include:: tests/scale_infrastructure_alerting.rst

.. _shutdown_influx_node:

Shutdown influxdb node
----------------------

.. include:: tests/shutdown_influx_node.rst

.. _shutdown_elasticsearch_node:

Shutdown elasticsearch node
---------------------------

.. include:: tests/shutdown_elasticsearch_node.rst

.. _shutdown_infrastructure_alerting_node:

Shutdown infrastructure alerting node
-------------------------------------

.. include:: tests/shutdown_infrastructure_alerting_node.rst

.. _query_logs_in_kibana_ui:

Display and query logs in the Kibana UI
---------------------------------------

.. include:: tests/query_logs_in_kibana_ui.rst

.. _query_nova_notifications_in_kibana_ui:

Display and query Nova notifications in the Kibana UI
-----------------------------------------------------

.. include:: tests/query_nova_notifications_in_kibana_ui.rst

.. _query_glance_notifications_in_kibana_ui:

Display and query Glance notifications in the Kibana UI
-------------------------------------------------------

.. include:: tests/query_glance_notifications_in_kibana_ui.rst

.. _query_cinder_notifications_in_kibana_ui:

Display and query Cinder notifications in the Kibana UI
-------------------------------------------------------

.. include:: tests/query_cinder_notifications_in_kibana_ui.rst

.. _query_heat_notifications_in_kibana_ui:

Display and query Heat notifications in the Kibana UI
-----------------------------------------------------

.. include:: tests/query_heat_notifications_in_kibana_ui.rst

.. _query_neutron_notifications_in_kibana_ui:

Display and query Neutron notifications in the Kibana UI
--------------------------------------------------------

.. include:: tests/query_neutron_notifications_in_kibana_ui.rst

.. _query_keystone_notifications_in_kibana_ui:

Display and query Keystone notifications in the Kibana UI
---------------------------------------------------------

.. include:: tests/query_keystone_notifications_in_kibana_ui.rst

.. _display_dashboards_in_grafana_ui:

Display the dashboards in the Grafana UI
----------------------------------------

.. include:: tests/display_dashboards_in_grafana_ui.rst

.. _display_nova_metrics_in_grafana_ui:

Display the Nova metrics in the Grafana UI
------------------------------------------

.. include:: tests/display_nova_metrics_in_grafana_ui.rst

.. _report_service_alerts_with_warning_severity:

Report service alerts with warning severity
-------------------------------------------

.. include:: tests/report_service_alerts_with_warning_severity.rst

.. _report_service_alerts_with_critical_severity:

Report service alerts with critical severity
--------------------------------------------

.. include:: tests/report_service_alerts_with_critical_severity.rst

.. _report_node_alerts_with_warning_severity:

Report node alerts with warning severity
----------------------------------------

.. include:: tests/report_node_alerts_with_warning_severity.rst

.. _report_node_alerts_with_critical_severity:

Report node alerts with critical severity
-----------------------------------------

.. include:: tests/report_node_alerts_with_critical_severity.rst

.. _non_functional_testing:

Non-functional testing
======================

.. _network_failure_on_analytics_node:

Simulate network failure on the analytics node
----------------------------------------------

.. include:: tests/network_failure_on_analytics_node.rst
