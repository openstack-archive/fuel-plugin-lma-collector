#!/bin/bash
# Copyright 2015 Mirantis, Inc.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

set -e

function convert_yes_no {
    if [[ ${1^^} == "YES" || ${1^} == "Y" || ${1} == "1" ]]; then
        echo "yes"
    else
        echo "no"
    fi
}

KIBANA_ENABLED=$(convert_yes_no "${KIBANA_ENABLED:-yes}")
GRAFANA_ENABLED=$(convert_yes_no "${GRAFANA_ENABLED:-yes}")

if [[ ${KIBANA_ENABLED} == "yes" ]]; then
    ES_HOST=${ES_HOST:-\"+window.location.hostname+\"}
    ES_PORT=9200
    ES_URL="http://${ES_HOST}:${ES_PORT}"
    echo "Elasticsearch URL is ${ES_URL}"

    cat <<EOF > /usr/share/nginx/html/kibana/config.js
define(['settings'],
function (Settings) {
  return new Settings({
    elasticsearch: "${ES_URL}",
    default_route     : '/dashboard/file/log.json',
    kibana_index: "kibana-int",
    panel_names: [
      'histogram',
      'map',
      'goal',
      'table',
      'filtering',
      'timepicker',
      'text',
      'hits',
      'column',
      'trends',
      'bettermap',
      'query',
      'terms',
      'stats',
      'sparklines'
    ]
  });
});
EOF
else
    echo "Kibana dashboard is disabled."
    rm -rf /usr/share/nginx/html/kibana
fi

if [[ ${GRAFANA_ENABLED} == "yes" ]]; then
    INFLUXDB_HOST=${INFLUXDB_HOST:-\"+window.location.hostname+\"}
    INFLUXDB_PORT=8086
    INFLUXDB_DBNAME=${INFLUXDB_DBNAME:-lma}
    INFLUXDB_USER=${INFLUXDB_USER:-lma}
    INFLUXDB_PASS=${INFLUXDB_PASS:-lmapass}
    INFLUXDB_URL="http://${INFLUXDB_HOST}:${INFLUXDB_PORT}"
    echo "InfluxDB URL is ${INFLUXDB_URL}"
    echo "InfluxDB database for metrics is ${INFLUXDB_DBNAME}"

    cat <<EOF > /usr/share/nginx/html/grafana/config.js
define(['settings'], function(Settings) {

  return new Settings({
      datasources: {
        lma: {
          type: 'influxdb',
          url: "${INFLUXDB_URL}/db/${INFLUXDB_DBNAME}",
          username: "${INFLUXDB_USER}",
          password: "${INFLUXDB_PASS}"
        },
        grafana: {
          type: 'influxdb',
          url: "${INFLUXDB_URL}/db/grafana",
          username: "${INFLUXDB_USER}",
          password: "${INFLUXDB_PASS}",
          grafanaDB: true
        },
      },

      search: {
        max_results: 100
      },

      default_route: '/dashboard/file/lma.json',

      unsaved_changes_warning: true,

      playlist_timespan: "1m",

      admin: {
        password: ''
      },

      window_title_prefix: 'LMA - ',

      plugins: {
        panels: [],
        dependencies: [],
      }

    });
});
EOF
else
    echo "Grafana dashboard is disabled."
    rm -rf /usr/share/nginx/html/grafana
fi

# disable ipv6 support
if [ ! -f /proc/net/if_inet6 ]; then
    sed -e '/listen \[::\]:80/ s/^#*/#/' -i /etc/nginx/sites-enabled/*
fi

echo "Starting nginx..."
nginx -c /etc/nginx/nginx.conf -g 'daemon off;'
