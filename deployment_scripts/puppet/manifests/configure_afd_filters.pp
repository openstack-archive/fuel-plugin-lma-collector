# Copyright 2015 Mirantis, Inc.
#
# Licensed under the Apache License, Version 2.0 (the "License"); you may
# not use this file except in compliance with the License. You may obtain
# a copy of the License at
#
#      http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS, WITHOUT
# WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. See the
# License for the specific language governing permissions and limitations
# under the License.

notice('fuel-plugin-lma-collector: configure_afd_filters.pp')

include lma_collector::params

$lma           = hiera_hash('lma_collector', {})
$roles         = node_roles(hiera('nodes'), hiera('uid'))
$is_controller = member($roles, 'controller') or member($roles, 'primary-controller')

$alarms_definitions = $lma['alarms']
if $alarms_definitions == undef {
    fail('Alarms definitions not found. Check files in /etc/hiera/override.')
}

if $is_controller {
  # On controllers make sure the Log collector service is configured
  # with the "pacemaker" provider
  include lma_collector::params
  Service<| title == $lma_collector::params::log_service_name |> {
    provider => 'pacemaker'
  }
  Service<| title == $lma_collector::params::metric_service_name |> {
    provider => 'pacemaker'
  }
}

class { 'fuel_lma_collector::afds':
    roles                  => hiera('roles'),
    node_cluster_roles     => $lma['node_cluster_roles'],
    service_cluster_roles  => $lma['service_cluster_roles'],
    node_cluster_alarms    => $lma['node_cluster_alarms'],
    service_cluster_alarms => $lma['service_cluster_alarms'],
    alarms                 => $alarms_definitions,
}

# Forward AFD status to Nagios if deployed
$network_metadata = hiera_hash('network_metadata')
$alerting_mode = $lma['alerting_mode']
if $alerting_mode == 'remote' {
  $nagios_enabled = true
  $nagios_url = $lma['nagios_url']
  $nagios_user = $lma['nagios_user']
  $nagios_password = $lma['nagios_password']
} elsif $alerting_mode == 'local' {
  $lma_infra_alerting = hiera_hash('lma_infrastructure_alerting', false)
  $infra_alerting_nodes = get_nodes_hash_by_roles($network_metadata, ['infrastructure_alerting', 'primary-infrastructure_alerting'])
  if size(keys($infra_alerting_nodes)) > 0 {
    $nagios_enabled = true
    if $network_metadata['vips']['infrastructure_alerting_mgmt_vip'] {
      $nagios_server = $network_metadata['vips']['infrastructure_alerting_mgmt_vip']['ipaddr']
    } else {
      # compatibility with the LMA Infrastructure Alerting plugin 0.8
      $nagios_nodes = get_nodes_hash_by_roles($network_metadata, ['infrastructure_alerting'])
      $nagios_server = $nagios_nodes[0]['internal_address']
    }
    $nagios_user = $lma_infra_alerting['nagios_user']
    $nagios_password = $lma_infra_alerting['nagios_password']
    $http_port = $lma_collector::params::nagios_http_port
    $http_path = $lma_collector::params::nagios_http_path
    $nagios_url = "http://${nagios_server}:${http_port}/${http_path}"
  } else {
    if ! $lma_infra_alerting {
      notice('Could not get the LMA Infrastructure Alerting parameters. The LMA-Infrastructure-Alerting plugin is probably not installed.')
    } elsif ! $lma_infra_alerting['metadata']['enabled'] {
      notice(join(['Could not get the LMA Infrastructure Alerting parameters. ',
        'The LMA-Infrastructure-Alerting plugin is probably not enabled for this environment.'], ''))
    } else {
      notice('The LMA-Infrastructure-Alerting plugin is enabled but no alerting node for this environment.')
    }
  }
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
