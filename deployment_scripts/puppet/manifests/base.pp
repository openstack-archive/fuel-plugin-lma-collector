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
# TODO(spasquier): fail if Neutron isn't used

prepare_network_config(hiera('network_scheme', {}))
$messaging_address = get_network_role_property('mgmt/messaging', 'ipaddr')
$lma_collector     = hiera_hash('lma_collector')
$roles             = node_roles(hiera('nodes'), hiera('uid'))
$is_controller     = member($roles, 'controller') or member($roles, 'primary-controller')
$is_base_os        = member($roles, 'base-os')
$current_node_name = hiera('user_node_name')
$current_roles     = hiera('roles')
$network_metadata  = hiera_hash('network_metadata')

$elasticsearch_kibana = hiera_hash('elasticsearch_kibana', {})
$es_nodes = filter_nodes(hiera('nodes'), 'role', 'elasticsearch_kibana')

$influxdb_grafana = hiera_hash('influxdb_grafana', {})
$influxdb_nodes = filter_nodes(hiera('nodes'), 'role', 'influxdb_grafana')

if $lma_collector['environment_label'] != '' {
  $environment_label = $lma_collector['environment_label']
} else {
  $environment_label = join(['env-', hiera('deployment_id')], '')
}
$tags = {
  deployment_id     => hiera('deployment_id'),
  openstack_region  => 'RegionOne',
  openstack_release => hiera('openstack_version'),
  openstack_roles   => join($roles, ','),
  environment_label => $environment_label,
}

if $is_controller {
  # "keystone" group required for lma_collector::logs::openstack to be able
  # to read log files located in /var/log/keystone
  $additional_groups = ['haclient', 'keystone']
  $pacemaker_managed = true
  $rabbitmq_resource = 'master_p_rabbitmq-server'
}else{
  $additional_groups = []
  $pacemaker_managed = false
  $rabbitmq_resource = undef
}

$elasticsearch_mode = $lma_collector['elasticsearch_mode']

case $elasticsearch_mode {
  'remote': {
    $es_server = $lma_collector['elasticsearch_address']
  }
  'local': {
    $vip_name = 'es_vip_mgmt'
    if $network_metadata['vips'][$vip_name] {
      $es_server = $network_metadata['vips'][$vip_name]['ipaddr']
    }else{
      # compatibility with elasticsearch-kibana version 0.8
      $es_server = $es_nodes[0]['internal_address']
    }
  }
  'disabled': {
    # Nothing to do
  }
  default: {
    fail("'${elasticsearch_mode}' mode not supported for Elasticsearch")
  }
}

# Notifications are always collected even when event indexation is disabled
if $is_controller{
  #$pre_script        = '/usr/local/bin/wait_for_rabbitmq'
  # Params used by the script.
  $rabbit            = hiera('rabbit')
  $rabbitmq_port     = hiera('amqp_port', '5673')
  $rabbitmq_host     = $messaging_address
  $rabbitmq_user     = 'nova'
  $rabbitmq_password = $rabbit['password']
  $wait_delay        = 30

  #  file { $pre_script:
  #    ensure  => present,
  #    owner   => 'root',
  #    group   => 'root',
  #    mode    => '0755',
  #    content => template('lma_collector/wait_for_rabbitmq.erb'),
  #    before  => Class['lma_collector']
  #  }
} else {
  $pre_script = undef
}

class { 'lma_collector':
  tags              => $tags,
  groups            => $additional_groups,
  pacemaker_managed => $pacemaker_managed,
  rabbitmq_resource => $rabbitmq_resource,
}

if $elasticsearch_mode != 'disabled' {
  class { 'lma_collector::logs::system':
    require => Class['lma_collector'],
  }

  if (str2bool($::ovs_log_directory)){
    # install logstreamer for open vSwitch if log directory exists
    class { 'lma_collector::logs::ovs':
      require => Class['lma_collector'],
    }
  }

  class { 'lma_collector::elasticsearch':
    server  => $es_server,
    require => Class['lma_collector'],
  }
}

$influxdb_mode = $lma_collector['influxdb_mode']
case $influxdb_mode {
  'remote','local': {
    if $influxdb_mode == 'remote' {
      $influxdb_server = $lma_collector['influxdb_address']
      $influxdb_database = $lma_collector['influxdb_database']
      $influxdb_user = $lma_collector['influxdb_user']
      $influxdb_password = $lma_collector['influxdb_password']
    }
    else {
      # Note: we don't validate data inputs because another manifest
      # is responsible to check their coherences.
      $influxdb_vip_name = 'influxdb'
      if $network_metadata['vips'][$influxdb_vip_name] {
        $influxdb_server = $network_metadata['vips'][$influxdb_vip_name]['ipaddr']
      } else {
        $influxdb_server = $influxdb_nodes[0]['internal_address']
      }
      $influxdb_database = $influxdb_grafana['influxdb_dbname']
      $influxdb_user = $influxdb_grafana['influxdb_username']
      $influxdb_password = $influxdb_grafana['influxdb_userpass']
    }

    if ! $is_controller {

      class { 'lma_collector::collectd::base':
        processes    => ['hekad', 'collectd'],
        read_threads => 5,
        require      => Class['lma_collector'],
      }
    }

    class { 'lma_collector::influxdb':
      server     => $influxdb_server,
      database   => $influxdb_database,
      user       => $influxdb_user,
      password   => $influxdb_password,
      tag_fields => ['deployment_id', 'environment_label', 'tenant_id', 'user_id'],
      require    => Class['lma_collector'],
    }

    class { 'lma_collector::metrics::heka_monitoring':
      require => Class['lma_collector']
    }

  }
  'disabled': {
    # Nothing to do
  }
  default: {
    fail("'${influxdb_mode}' mode not supported for InfluxDB")
  }
}
