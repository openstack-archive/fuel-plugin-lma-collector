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
# This script is intended to run on the Fuel master node. It will deploy all
# the pieces needed to run the LMA collector.
#
# It performs the following operations:
# * Build the LMA collector plugin.
# * Install the LMA collector plugin.
# * Deploy an Elasticsearch container
# * Deploy an InfluxDB container
# * Deploy a container for running the LMA dashboards.
#
# TODO: add script parameters to provide LMA password

set -e

function fail {
    echo "$1"
    exit 1
}

function info {
    echo "$1"
}

# Run pre-installation checks
if [[ "$(id -u)" != "0" ]]; then
    fail "This script needs to be run as root."
fi

if ! which docker 1>/dev/null; then
    fail "Couldn't find the docker binary."
fi

FUEL_VERSION_FILE="/etc/fuel/version.yaml"
if [ ! -f ${FUEL_VERSION_FILE} ]; then
    fail "This script needs to be run on the Fuel node."
fi

cat <<EOF | python -
import re
import sys
import yaml

release_re = "6\."
ok = False

with open("/etc/fuel/version.yaml") as f:
    data = yaml.load(f.read())
    ok = 'VERSION' in data and \
         'release' in data['VERSION'] and \
         re.match(release_re, data['VERSION']['release'])
if ok:
    sys.exit(0)
else:
    print "Fuel version not supported."
    sys.exit(1)
EOF

CURRENT_DIR=$(dirname "$(readlink -f "$0")")

UI_PORT=8081
PRIMARY_IP_ADDRESS=$(hostname --ip-address)
ES_DIR=/var/elasticsearch
MIN_MEM=$(( 1 * 1024 ))
MAX_MEM=$(( 32 * 1024 ))

FREE_MEM=$(free -m | egrep '^Mem:' | awk '{print $4}')

if [[ "$FREE_MEM" == "" ]]; then
    fail "Couldn't determine the amount of free RAM."
fi

if [[ $FREE_MEM -lt $MIN_MEM ]]; then
    fail "Need at least ${MIN_MEM}MB of free RAM while only ${FREE_MEM}MB are available."
fi

# Don't eat up all the free memory unless it is absolutely necessary
if [[ $FREE_MEM -gt $(( 2 * MIN_MEM )) ]]; then
    FREE_MEM=$(( FREE_MEM - MIN_MEM ))
fi

# There is no point of allocating more than 32GB of RAM to the JVM
if [[ $FREE_MEM -gt $MAX_MEM ]]; then
    FREE_MEM=$MAX_MEM
fi
ES_MEMORY=$(( FREE_MEM / 1024 ))

info "Starting the installation of the LMA collector plugin..."

yum install -y python-pip
pip install -U fuel-plugin-builder
if ! rpm -q epel-release-6-8.noarch; then
    rpm -Uvh http://download.fedoraproject.org/pub/epel/6/i386/epel-release-6-8.noarch.rpm
fi
yum install -y createrepo rpm dpkg-devel

info "Building the Fuel plugin..."
rm -f ../lma_collector*fp
if ! (cd "${CURRENT_DIR}/.." && fuel-plugin-builder --build ./); then
    fail "Failed to build the Fuel plugin."
fi

info "Installing the Fuel plugin..."
if ! (cd "${CURRENT_DIR}/.." && fuel plugins --force --install lma_collector*.fp); then
    fail "Failed to install the Fuel plugin."
fi

info "Building the documentation"
pip install Sphinx
if ! (cd "${CURRENT_DIR}/../doc" && make html); then
    info  "Couldn't build the documentation."
fi

info "Starting the Elasticsearch container..."
mkdir -p $ES_DIR
if ! (cd "${CURRENT_DIR}/elasticsearch" && ES_MEMORY=$ES_MEMORY ES_DATA=$ES_DIR ES_LISTEN_ADDRESS=$PRIMARY_IP_ADDRESS ./run_container.sh); then
    fail "Failed to start the Elasticsearch container."
fi

info "Starting the InfluxDB container..."
if ! (cd "${CURRENT_DIR}/influxdb" && LISTEN_ADDRESS=$PRIMARY_IP_ADDRESS ./run_container.sh); then
    fail "Failed to start the InfluxDB container."
fi

info "Starting the LMA UI container..."
if ! (cd "${CURRENT_DIR}/ui" && docker build -t lma_ui . && docker run -d -p ${UI_PORT}:80 --name lma_ui lma_ui); then
    fail "Failed to start the LMA UI container."
fi
info "Kibana dashboard available at http://${PRIMARY_IP_ADDRESS}:${UI_PORT}/kibana/"
info "Grafana dashboard available at http://${PRIMARY_IP_ADDRESS}:${UI_PORT}/grafana/"

info "The LMA collector storage and dashboard services are ready."
