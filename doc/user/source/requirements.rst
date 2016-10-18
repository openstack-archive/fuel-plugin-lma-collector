.. _plugin_requirements:

.. raw:: latex

   \pagebreak

Requirements
------------

The StackLight Collector plugin 1.0.0 has the following requirements:

+-------------------------------------------------------+-------------------------------------------------------------------+
| Requirement                                           | Version/Comment                                                   |
+=======================================================+===================================================================+
| Mirantis OpenStack                                    | 8.0, 9.x                                                          |
+-------------------------------------------------------+-------------------------------------------------------------------+
| A running Elasticsearch server (for log analytics)    | 1.7.4 or higher, the RESTful API must be enabled over port 9200   |
+-------------------------------------------------------+-------------------------------------------------------------------+
| A running InfluxDB server (for metric analytics)      | 0.10.0 or higher, the RESTful API must be enabled over port 8086  |
+-------------------------------------------------------+-------------------------------------------------------------------+
| A running Nagios server (for infrastructure alerting) | 3.5 or higher, the command CGI must be enabled                    |
+-------------------------------------------------------+-------------------------------------------------------------------+
