The scripts in this directory can be used to deploy the additional systems that
are running along with the Logging, Monitoring and Alerting collector.

# Pre-requisites

The scripts require the [Docker](https://www.docker.com/) runtime.

# Elasticsearch

[Elasticsearch](http://www.elasticsearch.org/overview/elasticsearch) is used to
store and index the logs and notifications gathered by the LMA collector.

To install the Elasticsearch stack, see (elasticsearch/README.md).

# InfluxDB

[InfluxDB](http://influxdb.com/) is used to store the metrics reported by the
LMA collector.

To install the InfluxDB stack, see (influxdb/README.md).

# LMA dashboards

The LMA dashboards are based on:

* [Kibana](http://www.elasticsearch.org/overview/kibana) for displaying and
  querying data in Elasticsearch.

* [Grafana](http://grafana.org/) for displaying and querying data in InfluxDB.

To install the dahsboards, see (ui/README.md).
