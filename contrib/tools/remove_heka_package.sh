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

FUEL_NODES_FILE=/tmp/nodes

. "$(dirname "$(readlink -f "$0")")"/common.sh

check_fuel_nodes_file "${FUEL_NODES_FILE}"

node_list=$(get_online_nodes "$(cat $FUEL_NODES_FILE)")

# Remove Heka due to the issue with heka package versionning
# https://github.com/mozilla-services/heka/issues/1892
echo "** Remove Heka package"
for n in $node_list; do
    echo "$n";
    ssh "$n" 'apt-get remove -y heka'
done
