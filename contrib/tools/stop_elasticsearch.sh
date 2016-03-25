#!/bin/bash
# Copyright 2016 Mirantis, Inc.
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

NODES_LIST_FILE=/tmp/nodes

. "$(dirname "$(readlink -f "$0")")"/common.sh

check_file_nodes_availability "${NODES_LIST_FILE}"

# Elasticsearch needs to be stopped for following necessary operations
# see https://bugs.launchpad.net/lma-toolchain/+bug/1559126
echo "** Stopping Elasticsearch"
for n in $(grep -E 'elasticsearch' $NODES_LIST_FILE | grep True | grep ready | awk -F '|' '{print $5}'); do
    echo "$n";
    ssh "$n" 'service elasticsearch-es-01 stop; ps aux|grep -v grep|grep java| grep elasticsearch && echo "** Elasticsearch is not stopped, you should try manually"'
done
