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
include lma_collector::params

$lma = hiera_hash('lma_collector', {})

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

# Forward AFD status to Nagios
$alerting_mode = $lma['alerting_mode']
if $alerting_mode == 'remote' {
  $nagios_enabled = true
  $nagios_url = $lma['nagios_url']
  $nagios_user = $lma['nagios_user']
  $nagios_password = $lma['nagios_password']
} elsif $alerting_mode == 'local' {
  $nagios_enabled = true
  $lma_infra_alerting = hiera_hash('lma_infrastructure_alerting', false)
  $network_metadata = hiera_hash('network_metadata')
  $nagios_server = $network_metadata['vips']['infrastructure_alerting']['ipaddr']
  $nagios_user = $lma_infra_alerting['nagios_user']
  $nagios_password = $lma_infra_alerting['nagios_password']
  $http_port = $lma_collector::params::nagios_http_port
  $http_path = $lma_collector::params::nagios_http_path
  $nagios_url = "http://${nagios_server}:${http_port}/${http_path}"
} else {
  $nagios_enabled = false
}

if $nagios_enabled {
  lma_collector::afd_nagios { 'nodes':
    ensure   => present,
    hostname => $::hostname,
    url      => $nagios_url,
    user     => $nagios_user,
    password => $nagios_password,
  }
}
