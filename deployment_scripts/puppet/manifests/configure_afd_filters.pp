#    Copyright 2015 Mirantis, Inc.
#
#    Licensed under the Apache License, Version 2.0 (the "License"); you may
#    not use this file except in compliance with the License. You may obtain
#    a copy of the License at
#
#         http://www.apache.org/licenses/LICENSE-2.0
#
#    Unless required by applicable law or agreed to in writing, software
#    distributed under the License is distributed on an "AS IS" BASIS, WITHOUT
#    WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. See the
#    License for the specific language governing permissions and limitations
#    under the License.
#

$lma = hiera_hash('lma_collector', undef)

$alarms_definitions = $lma['alarms']
if $alarms_definitions == undef {
    fail('Alarms definitions not found. Check files in /etc/hiera/override.')
}

class { 'lma_collector::afds':
    roles                  => hiera('roles'),
    node_cluster_roles     => $lma['node_cluster_roles'],
    service_cluster_roles  => $lma['service_cluster_roles'],
    node_cluster_alarms    => $lma['node_cluster_alarms'],
    service_cluster_alarms => $lma['service_cluster_alarms'],
    alarms                 => $alarms_definitions,
}
