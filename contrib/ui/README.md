# LMA user interface

Docker container for running the LMA dashboards (Kibana and Grafana).

## Build the image

From this directory:

`docker build -t lma_ui .`

## Run the image

`docker run -d -p 80:80 --name lma_ui lma_ui`

You can pass environment variables to the ``docker run`` command to override
the default parameters:

* ``KIBANA_ENABLED``, whether or not to enable the Kibana dashboard (default:
  "yes").

* ``GRAFANA_ENABLED``, whether or not to enable the Grafana dashboard (default:
  "yes").

* ``ES_HOST``, the address of the Elasticsearch server (default: same host).

* ``INFLUXDB_HOST``, the address of the InfluxDB server (default: same host).

* ``INFLUXDB_DBNAME``, the name of the InfluxDB database storing the metrics
  (default: "lma").

* ``INFLUXDB_USER``, the username for connecting to the InfluxDB databases
  (default: "lma").

* ``INFLUXDB_PASS``, the password for connecting to the InfluxDB databases
  (default: "lmapass").

If you want to save the Grafana dashboards into InfluxDB, you also need to
create a database named 'grafana' on the InfluxDB server. This database needs
to be accessible to the InfluxDB LMA user.

## Accessing the UI

The dashboards are available at the following URLs:

* http://<<span></span>container host>:<<span></span>public port>/kibana/
* http://<<span></span>container host>:<<span></span>public port>/grafana/

## Troubleshooting

If the dashboards fail to display the data or are unresponsive, run the
``docker logs lma_ui`` command and check that the Elasticsearch and InfluxDB
servers are reachable from the machine running the web browser.
