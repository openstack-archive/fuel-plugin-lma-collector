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

$ceilometer     = hiera('ceilometer')
$lma_collector  = hiera('lma_collector')
$rabbit         = hiera('rabbit')

if $ceilometer['enabled'] {
  $notification_topics = [$lma_collector::params::openstack_topic, $lma_collector::params::lma_topic]
}
else {
  $notification_topics = [$lma_collector::params::lma_topic]
}

if $rabbit['user'] {
  $rabbitmq_user = $rabbit['user']
}
else {
  $rabbitmq_user = 'nova'
}

if hiera('deployment_mode') =~ /^ha_/ {
  $ha_deployment = true
}else{
  $ha_deployment = false
}

# OpenStack notifcations are always useful for indexation and metrics collection
class { 'lma_collector::notifications::controller':
  host     => '127.0.0.1',
  port     => hiera('amqp_port', '5673'),
  user     => $rabbitmq_user,
  password => $rabbit['password'],
  topics   => $notification_topics,
}

# OpenStack logs are always useful for indexation and metrics collection
class { 'lma_collector::logs::openstack': }

# Logs
if $lma_collector['elasticsearch_mode'] != 'disabled' {

  class { 'lma_collector::logs::mysql': }

  class { 'lma_collector::logs::rabbitmq': }

  if $ha_deployment {
    class { 'lma_collector::logs::pacemaker': }
  }

}

# Metrics
if $lma_collector['influxdb_mode'] != 'disabled' {

  $nova           = hiera('nova')
  $neutron        = hiera('quantum_settings')
  $cinder         = hiera('cinder')
  $management_vip = hiera('management_vip')

  if $ha_deployment {
    $haproxy_socket = '/var/lib/haproxy/stats'
  }else{
    # do not deploy HAproxy collectd plugin
    $haproxy_socket = undef
  }

  $storage_options = hiera('storage', {})
  if $storage_options['volumes_ceph'] or $storage_options['images_ceph'] or $storage_options['objects_ceph'] or $storage_options['ephemeral_ceph']{
    $ceph_enabled = true
  } else {
    $ceph_enabled = false
  }

  class { 'lma_collector::collectd::controller':
    service_user      => 'nova',
    service_password  => $nova['user_password'],
    service_tenant    => 'services',
    keystone_url      => "http://${management_vip}:5000/v2.0",
    haproxy_socket    => $haproxy_socket,
    ceph_enabled      => $ceph_enabled,
    memcached_host    => hiera('internal_address'),
  }

  class { 'lma_collector::collectd::mysql':
    database => 'nova',
    username => 'nova',
    password => $nova['db_password'],
  }

  class { 'lma_collector::collectd::dbi':
  }

  lma_collector::collectd::dbi_services { 'nova':
    username        => 'nova',
    dbname          => 'nova',
    password        => $nova['db_password'],
    report_interval => 60,
    downtime_factor => 2,
    require  => Class['lma_collector::collectd::dbi'],
  }

  lma_collector::collectd::dbi_mysql_status{ 'mysql_status':
    username => 'nova',
    dbname   => 'nova',
    password => $nova['db_password'],
    require  => Class['lma_collector::collectd::dbi'],
  }

  lma_collector::collectd::dbi_services { 'cinder':
    username        => 'cinder',
    dbname          => 'cinder',
    password        => $cinder['db_password'],
    report_interval => 60,
    downtime_factor => 2,
    require  => Class['lma_collector::collectd::dbi'],
  }

  lma_collector::collectd::dbi_services { 'neutron':
    username        => 'neutron',
    dbname          => 'neutron',
    password        => $neutron['database']['passwd'],
    report_interval => 15,
    downtime_factor => 4,
    require  => Class['lma_collector::collectd::dbi'],
  }

  if $lma_collector['influxdb_legacy'] {
    class { 'lma_collector::logs::metrics_legacy': }
  } else {
    class { 'lma_collector::logs::metrics': }
  }

  # Notification are always collected, lets extract metrics from there
  class { 'lma_collector::notifications::metrics': }

  # Enable Apache status module
  class { 'lma_collector::mod_status': }

  # Enable service heartbeat metrics
  class { 'lma_collector::metrics::service_heartbeat':
    services => ['mysql', 'rabbitmq', 'haproxy', 'memcached', 'apache']
  }

  # Service status metrics and annotations
  class { 'lma_collector::metrics::service_status': }

  # Enable pacemaker resource location metrics
  if $ha_deployment {
    class { 'lma_collector::metrics::pacemaker_resources': }
  }
}

$nagios_mode = $lma_collector['nagios_mode']
if $nagios_mode != 'disabled' {

  $deployment_id = hiera('deployment_id')
  if $nagios_mode == 'remote' {
    $nagios_url = $lma_collector['nagios_url']
    $nagios_user = $lma_collector['nagios_user']
    $nagios_password = $lma_collector['nagios_password']
  } elsif $nagios_mode == 'local' {
    $lma_infra_alerting = hiera('lma_infrastructure_alerting', false)
    $nagios_node_name = $lma_infra_alerting['node_name']
    $nagios_nodes = filter_nodes(hiera('nodes'), 'user_node_name', $nagios_node_name)
    $nagios_server = $nagios_nodes[0]['internal_address']
    $nagios_user = $lma_infra_alerting['nagios_user']
    $nagios_password = $lma_infra_alerting['nagios_password']

    # Important: $http_port and $http_path must match the
    # lma_infra_monitoring configuration.
    $http_port = $lma_collector::params::nagios_http_port
    $http_path = $lma_collector::params::nagios_http_path
    $nagios_url = "http://${nagios_server}:${http_port}/${http_path}"
  } else {
    fail("'${nagios_mode}' mode not supported for the infrastructure alerting service")
  }

  class { 'lma_collector::nagios':
    openstack_deployment_name => $deployment_id,
    url => $nagios_url,
    user => $nagios_user,
    password => $nagios_password,
  }
}

