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
if hiera('lma::collector::infrastructure_alerting::server', false) {
  lma_collector::afd_nagios { 'nodes':
    ensure    => present,
    hostname  => $::hostname,
    server    => hiera('lma::collector::infrastructure_alerting::server'),
    user      => hiera('lma::collector::infrastructure_alerting::user'),
    password  => hiera('lma::collector::infrastructure_alerting::password'),
    http_port => hiera('lma::collector::infrastructure_alerting::http_port'),
    http_path => hiera('lma::collector::infrastructure_alerting::http_path'),
  }
}
