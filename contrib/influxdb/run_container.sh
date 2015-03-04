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
#
# Start a container running InfluxDB
#
# You can modify the following environment variables to tweak the configuration
#  - LISTEN_ADDRESS: listen address on the container host (default=127.0.0.1)
#  - LMA_DB: name of the LMA database (default=lma)
#  - LMA_USER: username for the LMA db (default=lma)
#  - LMA_PASSWORD: password for the LMA user (default=lmapass)
#  - ROOT_PASSWORD: password for the admin user (default=supersecret)

set -e

CURRENT_DIR=$(dirname $(readlink -f $0))
[[ -f ${CURRENT_DIR}/../common/functions.sh ]] && . ${CURRENT_DIR}/../common/functions.sh

DOCKER_NAME=influxdb
DOCKER_IMAGE="tutum/influxdb"
RUN_TIMEOUT=30
INFLUXDB_LISTEN_ADDRESS=${LISTEN_ADDRESS:-127.0.0.1}
INFLUXDB_GRAFANA_DB=grafana
INFLUXDB_LMA_DB=${LMA_DB:-lma}
INFLUXDB_LMA_USER=${LMA_USER:-lma}
INFLUXDB_LMA_PASSWORD=${LMA_PASSWORD:-lmapass}
INFLUXDB_ROOT_PASSWORD=${ROOT_PASSWORD:-supersecret}
INFLUXDB_URL="http://${INFLUXDB_LISTEN_ADDRESS}:8086"

if [[ "$(docker_get_id $DOCKER_NAME)" != "" ]]; then
    echo "Docker container '${DOCKER_NAME}' already exists! Please remove it first."
    exit 1
fi

docker_pull_image $DOCKER_IMAGE

DOCKER_ID=$(timeout $RUN_TIMEOUT docker run -d -p ${INFLUXDB_LISTEN_ADDRESS}:8083:8083 -p ${INFLUXDB_LISTEN_ADDRESS}:8086:8086  --expose 8090 --expose 8099 --name ${DOCKER_NAME} ${DOCKER_IMAGE})
SHORT_ID=$(docker_shorten_id $DOCKER_ID)

echo -n "Waiting for InfluxDB to be up"
while ! curl ${INFLUXDB_URL} 1>/dev/null 2>&1; do
    echo -n '.'
    if ! docker_is_running $DOCKER_ID; then
        echo ''
        echo "Container '${DOCKER_NAME}/${SHORT_ID}' failed to start!"
        docker logs $DOCKER_ID
        exit 1
    fi
    sleep 1
done
echo
echo "Container '${DOCKER_NAME}/${SHORT_ID}' started successfully"

curl -X POST "${INFLUXDB_URL}/cluster_admins/root?u=root&p=root" -d '{"password": "'${INFLUXDB_ROOT_PASSWORD}'"}'

curl -X POST "${INFLUXDB_URL}/db?u=root&p=${INFLUXDB_ROOT_PASSWORD}" -d '{"name": "'${INFLUXDB_LMA_DB}'"}'
curl -X POST "${INFLUXDB_URL}/db/${INFLUXDB_LMA_DB}/users?u=root&p=${INFLUXDB_ROOT_PASSWORD}" -d '{"name": "'${INFLUXDB_LMA_USER}'", "password": "'${INFLUXDB_LMA_PASSWORD}'"}'
echo "InfluxDB provisioned with db=${INFLUXDB_LMA_DB}, user=${INFLUXDB_LMA_USER}, pass=${INFLUXDB_LMA_PASSWORD}"

curl -X POST "${INFLUXDB_URL}/db?u=root&p=${INFLUXDB_ROOT_PASSWORD}" -d '{"name": "'${INFLUXDB_GRAFANA_DB}'"}'
curl -X POST "${INFLUXDB_URL}/db/${INFLUXDB_GRAFANA_DB}/users?u=root&p=${INFLUXDB_ROOT_PASSWORD}" -d '{"name": "'${INFLUXDB_LMA_USER}'", "password": "'${INFLUXDB_LMA_PASSWORD}'"}'
echo "InfluxDB provisioned with db=${INFLUXDB_GRAFANA_DB}, user=${INFLUXDB_LMA_USER}, pass=${INFLUXDB_LMA_PASSWORD}"

echo "InfluxDB API available at ${INFLUXDB_URL}"
