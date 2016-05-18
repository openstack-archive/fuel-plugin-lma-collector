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

prepare_network_config(hiera('network_scheme', {}))
$mgmt_address = get_network_role_property('management', 'ipaddr')

$influxdb_grafana = hiera('influxdb_grafana')

if hiera('lma::influxdb::is_deployed', false) {
  $network_metadata = hiera('network_metadata')

  $is_elasticsearch_node = roles_include(['elasticsearch_kibana', 'primary-elasticsearch_kibana'])
  $is_influxdb_node = roles_include(['influxdb_grafana', 'primary-influxdb_grafana'])

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
        password => $influxdb_grafana['influxdb_rootpass'],
        address  => hiera('lma::influxdb::listen_address', $mgmt_address),
        port     => hiera('lma::influxdb::influxdb_port', 8086)
    }
  }

  if $is_elasticsearch_node {
    class { 'lma_collector::collectd::elasticsearch':
      address => hiera('lma::elasticsearch::vip', $mgmt_address),
      port    => hiera('lma::elasticsearch::rest_port', 9200)
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
