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

$lma           = hiera_hash('lma_collector', {})
$is_controller = roles_include(['controller', 'primary-controller'])
$is_rabbitmq   = roles_include(['standalone-rabbitmq', 'primary-standalone-rabbitmq'])
$is_mysql_server = roles_include(['standalone-database', 'primary-standalone-database'])

$alarms_definitions = $lma['alarms']
if $alarms_definitions == undef {
    fail('Alarms definitions not found. Check files in /etc/hiera/override.')
}

if $is_controller or $is_rabbitmq or $is_mysql_server {
  # On nodes where pacemaker is deployed, make sure the LMA service is
  # configured with the "pacemaker" provider
  Service<| title == 'log_collector' |> {
    provider => 'pacemaker'
  }
  Service<| title == 'metric_collector' |> {
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
    # Important: $http_port and $http_path must match the
    # lma_infra_monitoring configuration.
    $http_port = 8001
    $http_path = 'status'
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
