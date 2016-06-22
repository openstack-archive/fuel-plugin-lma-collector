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

prepare_network_config(hiera_hash('network_scheme', {}))
$plugin_data = hiera_hash('lma_collector', undef)

if ($plugin_data) {
  $network_metadata = hiera_hash('network_metadata')
  $is_controller_node = roles_include(['controller', 'primary-controller'])
  $is_base_os_node = roles_include('base-os')

  if $plugin_data['environment_label'] != '' {
    $environment_label = $plugin_data['environment_label']
  } else {
    $environment_label = join(['env-', hiera('deployment_id')], '')
  }

  if roles_include(['standalone-database', 'primary-standalone-database']) {
    $is_mysql_node = true
  } else {
    $is_mysql_node = $is_controller_node
  }

  if roles_include(['standalone-rabbitmq', 'primary-standalone-rabbitmq']) {
    $is_rabbitmq_node = true
  } else {
    $is_rabbitmq_node = $is_controller_node
  }

  $has_controller = count(get_nodes_hash_by_roles($network_metadata, ['primary-controller'])) > 0

  # Elasticsearch
  $is_elasticsearch_node = roles_include(['elasticsearch_kibana', 'primary-elasticsearch_kibana'])
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
  $is_influxdb_node = roles_include(['influxdb_grafana', 'primary-influxdb_grafana'])
  $influxdb_mode = $plugin_data['influxdb_mode']
  $influxdb_nodes = get_nodes_hash_by_roles($network_metadata, ['influxdb_grafana', 'primary-influxdb_grafana'])
  $influxdb_nodes_count = count($influxdb_nodes)
  $influxdb_grafana = hiera_hash('influxdb_grafana', {})

  case $influxdb_mode {
    'remote': {
      $influxdb_server = $plugin_data['influxdb_address']
      $influxdb_database = $plugin_data['influxdb_database']
      $influxdb_user = $plugin_data['influxdb_user']
      $influxdb_password = $plugin_data['influxdb_password']
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
      $influxdb_root_password = $influxdb_grafana['influxdb_rootpass']
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
  if $has_controller {
    $nova = hiera_hash('nova', {})
    $mysql_username = 'nova'
    $mysql_password = $nova['db_password']
    $mysql_db = 'nova'
  } elsif $is_mysql_node {
      $influxdb_plugin = hiera_hash('influxdb_grafana', {})
      if $influxdb_plugin['mysql_mode'] == 'local' {
        # Use the Grafana credentials when the MySQL server is deployed in the
        # same environment but without controller (eg dedicated environment scenario)
        $mysql_username = $influxdb_plugin['mysql_username']
        $mysql_password = $influxdb_plugin['mysql_password']
        $mysql_db = $influxdb_plugin['mysql_db']
      }
  }

  # GSE
  $gse_service = $plugin_data['gse_cluster_service']
  $gse_node = $plugin_data['gse_cluster_node']
  $gse_global = $plugin_data['gse_cluster_global']
  $gse_policies =  $plugin_data['gse_policies']

  # cluster
  $node_cluster_roles = $plugin_data['node_cluster_roles']
  $service_cluster_roles = $plugin_data['service_cluster_roles']
  $node_cluster_alarms = $plugin_data['node_cluster_alarms']
  $service_cluster_alarms = $plugin_data['service_cluster_alarms']

  # Alarms
  $alarms = $plugin_data['alarms']

  # Infrastructure Alerting
  $alerting_mode = $plugin_data['alerting_mode']
  $lma_infra_alerting = hiera('lma_infrastructure_alerting', {})
  $infra_alerting_nodes = get_nodes_hash_by_roles($network_metadata, ['infrastructure_alerting', 'primary-infrastructure_alerting'])
  $infra_alerting_nodes_count = count($infra_alerting_nodes)

  case $alerting_mode {
    'local': {
      $infra_vip_name = 'infrastructure_alerting_mgmt_vip'
      if $network_metadata['vips'][$infra_vip_name] {
        $nagios_server = $network_metadata['vips'][$infra_vip_name]['ipaddr']
      } elsif $infra_alerting_nodes_count > 0 {
        $nagios_server = $infra_alerting_nodes[0]['internal_address']
      } else {
        $nagios_server = undef
      }
      $nagios_password = $lma_infra_alerting['nagios_password']
      $message_type = $plugin_data['gse_cluster_global']['output_message_type']
    }
    'standalone': {
      $send_from = $plugin_data['alerting_send_from']
      $send_to   = $plugin_data['alerting_send_to']
      $smtp_host = $plugin_data['alerting_smtp_host']
      $smtp_auth = $plugin_data['alerting_smtp_auth']
      $smtp_user = $plugin_data['alerting_smtp_user']
      $smtp_password = $plugin_data['alerting_smtp_password']
    }
    default: {
      fail("'${alerting_mode}' mode not supported for Nagios")
    }
  }

  if $infra_alerting_nodes_count > 0 or $nagios_server {
    $nagios_is_deployed = true
  } else {
    $nagios_is_deployed = false
  }

  $hiera_file = '/etc/hiera/plugins/lma_collector.yaml'

  $calculated_content = inline_template('
---
lma::collector::environment_label: <%= @environment_label %>
lma::collector::node_profiles:
  controller: <%= @is_controller_node %>
  influxdb: <%= @is_influxdb_node %>
  elasticsearch: <%= @is_elasticsearch_node %>
  rabbitmq: <%= @is_rabbitmq_node %>
  mysql: <%= @is_mysql_node %>
  base_os: <%= @is_base_os_node %>

lma::collector::monitor::mysql_db: <%= @mysql_db %>
lma::collector::monitor::mysql_username: <%= @mysql_username %>
lma::collector::monitor::mysql_password: <%= @mysql_password %>

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
lma::collector::influxdb::root_password: <%= @influxdb_root_password %>
<% end -%>

lma::collector::gse::service: <%= @gse_service %>
lma::collector::gse::node: <%= @gse_node %>
lma::collector::gse::global: <%= @gse_global %>
lma::collector::gse::policies: <%= @gse_policies %>

lma::collector::cluster::node_roles: <%= @node_cluster_roles %>
lma::collector::cluster::service_roles: <%= @service_cluster_roles %>
lma::collector::cluster::node_alarms: <%= @node_cluster_alarms %>
lma::collector::cluster::service_alarms: <%= @service_cluster_alarms %>

lma::collector::alarms: <%= @alarms %>

lma::collector::infrastrucutre_alerting::mode: <%= @alerting_mode %>
<% if @nagios_is_deployed -%>
lma::collector::infrastructure_alerting::server: <%= @nagios_server %>
lma::collector::infrastructure_alerting::http_port: 8001
lma::collector::infrastructure_alerting::http_path: status
lma::collector::infrastructure_alerting::user: nagiosadmin
lma::collector::infrastructure_alerting::password: <%= @nagios_password %>
lma::collector::infrastructure_alerting::message_type: <%= @message_type %>

<% end -%>
<% if @alerting_mode == "standalone" -%>
lma::collector::infrastructure_alerting::send_from: <%= @send_from %>
lma::collector::infrastructure_alerting::send_to: <%= @send_to %
lma::collector::infrastructure_alerting::smtp_host: <%= @smtp_host %>
lma::collector::infrastructure_alerting::smtp_auth: <%= @smtp_auth %>
lma::collector::infrastructure_alerting::smtp_user: <%= @smtp_user %>
lma::collector::infrastructure_alerting::smtp_password: <%= @smtp_password %>
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
