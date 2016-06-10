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

function check_fuel_nodes_file {
    if [ ! -f "$1" ]; then
      echo "You must first run the following command on the Fuel master node:"
      echo "  fuel nodes > $1"
      exit 1
    fi
}

# Get IPs list of online nodes from 'fuel command' output.
function get_online_nodes {
   # "fuel nodes" command output differs form Fuel 8 and 9 for online nodes: True/False and 0/1
   fuel nodes | grep ready | awk -F '|' -vOFS=':' '{print $5,$9 }'|tr -d ' '|grep -E ':1|:True'|awk -F ':' '{print $1}'
}
