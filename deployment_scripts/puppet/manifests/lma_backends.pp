# Copyright 2016 Mirantis, Inc.
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

notice('fuel-plugin-lma-collector: lma_backends.pp')

prepare_network_config(hiera_hash('network_scheme', {}))
$mgmt_address = get_network_role_property('management', 'ipaddr')


if hiera('lma::collector::influxdb::server', false) {
  $network_metadata = hiera_hash('network_metadata')

  $node_profiles = hiera_hash('lma::collector::node_profiles')
  $is_elasticsearch_node = $node_profiles['elasticsearch']
  $is_influxdb_node = $node_profiles['influxdb']

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

  if $is_influxdb_node {
    class { 'lma_collector::collectd::influxdb':
        username => 'root',
        password => hiera('lma::collector::influxdb::root_password'),
        address  => hiera('lma::collector::influxdb::listen_address'),
        port     => hiera('lma::collector::influxdb::influxdb_port', 8086)
    }
  }

  if $is_elasticsearch_node {
    class { 'lma_collector::collectd::elasticsearch':
      address => hiera('lma::collector::elasticsearch::server'),
      port    => hiera('lma::collector::elasticsearch::rest_port', 9200)
    }
  }

  if $network_metadata['vips']['influxdb'] or $network_metadata['vips']['es_vip_mgmt'] {
    # Only when used with the version 0.9 (and higher) of the
    # Elasticsearch-Kibana and InfluxDB-Grafana plugins
    class { 'lma_collector::collectd::haproxy':
      socket => '/var/lib/haproxy/stats',
    }
  }
}
