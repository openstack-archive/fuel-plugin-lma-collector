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

. common.sh

check_file_nodes_availability "${NODES_LIST_FILE}"

# collectd processes could be wedge, stop or kill them
# see https://bugs.launchpad.net/lma-toolchain/+bug/1560946
echo "** Stopping Collectd"
for n in $(grep True $NODES_LIST_FILE|grep ready|awk -F '|' '{print $5}'); do
    echo "$n";
    ssh "$n" '/etc/init.d/collectd  stop; pkill -9 collectd'
done

# Several hekad process may run on these nodes, stop or kill them
# see https://bugs.launchpad.net/lma-toolchain/+bug/1561109
echo "** Stopping Heka"
for n in $(grep -E 'osd|compute|cinder|elasticsearch|influxdb|alerting' $NODES_LIST_FILE|grep True|grep ready|awk -F '|' '{print $5}'); do
    echo "$n";
    ssh "$n" 'service lma_collector stop; pkill -TERM hekad; sleep 5; pkill -9 hekad;'
done

# Stop heka on controllers during the upgrade to avoid losing logs and notification
# (because elasticsearch will be stopped and heka doesn't buffering data with 0.8.0)
echo "** Stopping Heka on controller(s)"
for n in $(grep controller $NODES_LIST_FILE|grep True|grep ready|awk -F '|' '{print $5}'|tail -n 1); do
    echo "$n";
    ssh "$n" 'crm resource stop lma_collector'
done
