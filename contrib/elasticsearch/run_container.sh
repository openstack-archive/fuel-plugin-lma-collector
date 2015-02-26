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
# Start a container running ElasticSearch
#
# You can modify the following environment variables to tweak the configuration
#  - ES_DATA: directory where to store the ES data and logs (default=~/es_volume)
#  - ES_MEMORY: amount of memory (in Gb) allocated to the JVM (default=16)
#  - ES_LISTEN_ADDRESS: listen address on the container host (default=127.0.0.1)

set -e

CURRENT_DIR=$(dirname $(readlink -f $0))
[[ -f ${CURRENT_DIR}/../common/functions.sh ]] && . ${CURRENT_DIR}/../common/functions.sh

DOCKER_NAME=elasticsearch
DOCKER_IMAGE="dockerfile/elasticsearch"
RUN_TIMEOUT=60
ES_DATA=${ES_DATA:-~/es_volume}
ES_MEMORY=${ES_MEMORY:-16}
# We don't want to accidently expose the ES ports on the Internet so we only
# publish ports on the host's loopback address. To access ElasticSearch from
# another host, you can SSH to the Docker host with port forwarding (eg
# '-L 9200:127.0.0.1:9200').
# Or you can override the ES_LISTEN_ADDRESS variable...
ES_LISTEN_ADDRESS=${ES_LISTEN_ADDRESS:-127.0.0.1}
ES_HTTP_PORT=${ES_HTTP_PORT:-9200}
ES_TRANSPORT_PORT=${ES_TRANSPORT_PORT:-9300}
ES_URL="http://${ES_LISTEN_ADDRESS}:${ES_HTTP_PORT}"

if [[ "$(docker_get_id $DOCKER_NAME)" != "" ]]; then
    echo "Docker container '${DOCKER_NAME}' already exists! Please remove it first."
    exit 1
fi

if [[ ! -d $ES_DATA ]]; then
    mkdir $ES_DATA
elif [[ -f ${ES_DATA}/elasticsearch.yml ]]; then
    echo "Warning: ${ES_DATA}/elasticsearch.yaml already exists."
fi

cat <<EOF > $ES_DATA/elasticsearch.yml
#cluster.name: elastic_lma
node.name: $(hostname)
bootstrap.mlockall: true
path:
  logs: /data/log
  data: /data/data
# This is required for Kibana 3.x
http.cors.enabled: true
EOF

docker_pull_image ${DOCKER_IMAGE}

DOCKER_ID=$(timeout $RUN_TIMEOUT docker run -d -e ES_HEAP_SIZE=${ES_MEMORY}g -p ${ES_LISTEN_ADDRESS}:${ES_HTTP_PORT}:9200 -p ${ES_LISTEN_ADDRESS}:${ES_TRANSPORT_PORT}:9300 --name ${DOCKER_NAME} -v $ES_DATA:/data ${DOCKER_IMAGE} /elasticsearch/bin/elasticsearch -Des.config=/data/elasticsearch.yml)
SHORT_ID=$(docker_shorten_id $DOCKER_ID)

echo -n "Waiting for ElasticSearch to start"
while ! curl http://${ES_LISTEN_ADDRESS}:${ES_HTTP_PORT} 1>/dev/null 2>&1; do
    echo -n '.'
    IS_RUNNING=$(docker inspect --format="{{ .State.Running }}" ${DOCKER_ID})
    if [[ "${IS_RUNNING}" == "false" ]]; then
        echo ''
        echo "Container '${DOCKER_NAME}/${SHORT_ID}' failed to start!"
        docker logs $DOCKER_ID
        exit 1
    fi
    sleep 1
done
echo

echo "Container '${DOCKER_NAME}/${SHORT_ID}' started successfully"

# Configure template for 'log-*' and 'notification-*' indices
curl -s -XDELETE ${ES_URL}/_template/log 1>/dev/null
curl -s -XPUT -d @log_index_template.json ${ES_URL}/_template/log 1>/dev/null
curl -s -XPUT -d @notification_index_template.json ${ES_URL}/_template/notification 1>/dev/null

echo "ElasticSearch API avaiable at ${ES_URL}"
