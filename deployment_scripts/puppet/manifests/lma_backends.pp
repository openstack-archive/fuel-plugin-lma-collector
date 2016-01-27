#    Copyright 2016 Mirantis, Inc.
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

$lma_collector_hash = hiera_hash('lma_collector')
$influxdb_grafana = hiera('influxdb_grafana')

if $lma_collector_hash['influxdb_mode'] != 'disabled' {
  $network_metadata = hiera('network_metadata')
  $current_roles    = hiera('roles')

  $is_elasticsearch_node = member($current_roles, 'elasticsearch_kibana') or member($current_roles, 'primary-elasticsearch_kibana')
  $is_influxdb_node = member($current_roles, 'influxdb_grafana') or member($current_roles, 'primary-influxdb_grafana')

  if $is_elasticsearch_node {
    $process_matches = [{name => 'elasticsearch', regex => 'java'}]
  } else {
    $process_matches = undef
  }

  if $is_influxdb_node {
    $processes = ['influxd', 'grafana-server', 'hekad', 'collectd']
  } else {
    $processes = ['hekad', 'collectd']
  }

  class { 'lma_collector::collectd::base':
    processes       => $processes,
    process_matches => $process_matches,
  }

  if member($current_roles, 'primary-influxdb_grafana') {
    class { 'lma_collector::collectd::influxdb':
        username => 'root',
        password => $influxdb_grafana['influxdb_rootpass'],
    }
  }

  if $is_elasticsearch_node {
    class { 'lma_collector::collectd::elasticsearch':
      address => hiera('lma::elasticsearch::vip'),
    }
  }

  class { 'lma_collector::collectd::haproxy':
    socket => '/var/lib/haproxy/stats',
  }
}
