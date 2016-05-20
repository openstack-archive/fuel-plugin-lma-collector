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

notice('fuel-plugin-lma-collector: hiera_override.pp')

prepare_network_config(hiera('network_scheme', {}))
$plugin_data = hiera_hash('lma_collector', undef)

if ($plugin_data) {
  $network_metadata = hiera_hash('network_metadata')

  # Elasticsearch
  $elasticsearch_mode = $plugin_data['elasticsearch_mode']
  $es_nodes = get_nodes_hash_by_roles($network_metadata, ['elasticsearch_kibana', 'primary-elasticsearch_kibana'])
  $es_nodes_count = count($es_nodes)

  case $elasticsearch_mode {
    'remote': {
      $es_server = $plugin_data['elasticsearch_address']
      $monitor_elasticsearch = false
    }
    'local': {
      $es_vip_name = 'es_vip_mgmt'
      if $network_metadata['vips'][$es_vip_name] {
        $es_server = $network_metadata['vips'][$es_vip_name]['ipaddr']
        $monitor_elasticsearch = true
      } elsif $es_nodes_count > 0 {
        $es_server = $es_nodes[0]['internal_address']
        $monitor_elasticsearch = true
      } else {
        $es_server = undef
        $monitor_elasticsearch = false
      }
    }
    default: {
      fail("'${elasticsearch_mode}' mode not supported for Elasticsearch")
    }
  }
  if $es_nodes_count > 0 or $es_server {
    $es_is_deployed = true
  } else {
    $es_is_deployed = false
  }

  # InfluxDB
  $influxdb_mode = $plugin_data['influxdb_mode']
  $influxdb_nodes = get_nodes_hash_by_roles($network_metadata, ['influxdb_grafana', 'primary-influxdb_grafana'])
  $influxdb_nodes_count = count($influxdb_nodes)
  $influxdb_grafana = hiera_hash('influxdb_grafana', {})

  case $influxdb_mode {
    'remote': {
      $influxdb_server = $plugin_data['influxdb_address']
      $influxdb_database = $lma_collector['influxdb_database']
      $influxdb_user = $lma_collector['influxdb_user']
      $influxdb_password = $lma_collector['influxdb_password']
      $monitor_influxdb = false
    }
    'local': {
      $influxdb_vip_name = 'influxdb'
      if $network_metadata['vips'][$influxdb_vip_name] {
        $influxdb_server = $network_metadata['vips'][$influxdb_vip_name]['ipaddr']
        $monitor_influxdb = true
      } elsif $influxdb_nodes_count > 0 {
        $influxdb_server = $influxdb_nodes[0]['internal_address']
        $monitor_influxdb = true
      } else {
        $monitor_influxdb = false
        $influxdb_server = undef
      }
      $influxdb_database = $influxdb_grafana['influxdb_dbname']
      $influxdb_user = $influxdb_grafana['influxdb_username']
      $influxdb_password = $influxdb_grafana['influxdb_userpass']
    }
    default: {
      fail("'${influxdb_mode}' mode not supported for InfluxDB")
    }
  }
  if $influxdb_nodes_count > 0 or $influxdb_server {
    $influxdb_is_deployed = true
  } else {
    $influxdb_is_deployed = false
  }

  $hiera_file = '/etc/hiera/plugins/lma_collector.yaml'

  $calculated_content = inline_template('
---
<% if @es_is_deployed -%>
lma::collector::elasticsearch::server: <%= @es_server %>
lma::collector::elasticsearch::rest_port: 9200
<% end -%>
<% if @influxdb_is_deployed -%>
lma::collector::influxdb::server: <%= @influxdb_server %>
lma::collector::influxdb::port: 8086
lma::collector::influxdb::database: <%= @influxdb_database %>
lma::collector::influxdb::user: <%= @influxdb_user %>
lma::collector::influxdb::password: <%= @influxdb_password %>
<% end -%>
  ')

  file { $hiera_file:
    ensure  => file,
    content => $calculated_content,
  }

  $storage_options = hiera_hash('storage', {})
  $tls_enabled = hiera('public_ssl', false)
  $ceilometer = hiera_hash('ceilometer', {})
  $ceilometer_enabled = pick($ceilometer['enabled'], false)
  $contrail_plugin = hiera('contrail', false)

  # detach_rabbitmq_enabled is used in templates
  $detach_rabbitmq = hiera('detach-rabbitmq', {})
  $detach_rabbitmq_enabled = $detach_rabbitmq['metadata'] and $detach_rabbitmq['metadata']['enabled']

  # detach_database_enabled is used in templates
  $detach_database = hiera('detach-database', {})
  $detach_database_enabled = $detach_database['metadata'] and $detach_database['metadata']['enabled']

  fuel_lma_collector::hiera_data { 'gse_filters':
    content => template('fuel_lma_collector/gse_filters.yaml.erb')
  }

  fuel_lma_collector::hiera_data { 'alarming':
    content => template('fuel_lma_collector/alarming.yaml.erb')
  }
}
