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

# produce the following output for all VIP resources:
# <resource-name> <node> <active>
#
# where:
#  <resource-name>: name of the resource (ie vip__public)
#  <node>: the hostname of the node where the resource is located (ie node-1)
#  <active>: either '0' or '1' if <node> matches the local hostname

host=$(hostname -s)

for rsr in vip__public vip__management vip__public_vrouter vip__management_vrouter; do
  node=$(/usr/sbin/crm_resource --locate --quiet --resource  $rsr 2>/dev/null)
  if [ $? -eq 0 ]; then
    if [[ x"$host" = x"$node" ]]; then
        iam=1
    else
        iam=0
    fi
    echo $rsr $node $iam
  fi
done
exit 0
