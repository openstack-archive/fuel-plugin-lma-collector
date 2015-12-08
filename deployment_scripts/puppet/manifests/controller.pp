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
prepare_network_config(hiera('network_scheme', {}))
$messaging_address = get_network_role_property('mgmt/messaging', 'ipaddr')
$memcache_address  = get_network_role_property('mgmt/memcache', 'ipaddr')

include lma_collector::params

$ceilometer      = hiera_hash('ceilometer', {})
$lma_collector   = hiera_hash('lma_collector')
$rabbit          = hiera_hash('rabbit')
$management_vip  = hiera('management_vip')
$storage_options = hiera_hash('storage', {})
$murano          = hiera_hash('murano')

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

# OpenStack notifications are always useful for indexation and metrics collection
class { 'lma_collector::notifications::controller':
  host     => $messaging_address,
  port     => hiera('amqp_port', '5673'),
  user     => $rabbitmq_user,
  password => $rabbit['password'],
  topics   => $notification_topics,
}

# OpenStack logs are always useful for indexation and metrics collection
#class { 'lma_collector::logs::openstack_7_0': }

lma_collector::logs::openstack { 'nova': }
lma_collector::logs::openstack { 'neutron': }
lma_collector::logs::openstack { 'keystone': }
lma_collector::logs::openstack { 'cinder': }
lma_collector::logs::openstack { 'glance': }
lma_collector::logs::openstack { 'heat': }
if $murano['enabled'] {
  lma_collector::logs::openstack { 'murano': }
}
if ! $storage_options['objects_ceph'] {
  class { 'lma_collector::logs::swift':
    file_match => 'swift-all\.log$',
  }
}

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

  $nova           = hiera_hash('nova', {})
  $neutron        = hiera_hash('quantum_settings', {})
  $cinder         = hiera_hash('cinder', {})

  if $ha_deployment {
    $haproxy_socket = '/var/lib/haproxy/stats'
  }else{
    # do not deploy HAproxy collectd plugin
    $haproxy_socket = undef
  }

  if $storage_options['volumes_ceph'] or $storage_options['images_ceph'] or $storage_options['objects_ceph'] or $storage_options['ephemeral_ceph']{
    $ceph_enabled = true
  } else {
    $ceph_enabled = false
  }

  class { 'lma_collector::collectd::controller':
    service_user              => 'nova',
    service_password          => $nova['user_password'],
    service_tenant            => 'services',
    keystone_url              => "http://${management_vip}:5000/v2.0",
    haproxy_socket            => $haproxy_socket,
    ceph_enabled              => $ceph_enabled,
    memcached_host            => $memcache_address,
    pacemaker_resources       => [
        'vip__public',
        'vip__management',
        'vip__vrouter_pub',
        'vip__vrouter',
    ],
    pacemaker_master_resource => 'vip__management',
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
    require         => Class['lma_collector::collectd::dbi'],
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
    require         => Class['lma_collector::collectd::dbi'],
  }

  lma_collector::collectd::dbi_services { 'neutron':
    username        => 'neutron',
    dbname          => 'neutron',
    password        => $neutron['database']['passwd'],
    report_interval => 15,
    downtime_factor => 4,
    require         => Class['lma_collector::collectd::dbi'],
  }

  class { 'lma_collector::logs::metrics': }

  # Notification are always collected, lets extract metrics from there
  class { 'lma_collector::notifications::metrics': }

  # Enable Apache status module
  class { 'lma_collector::mod_status': }

  # Enable service heartbeat metrics
  class { 'lma_collector::metrics::service_heartbeat':
    services => ['haproxy', 'memcached']
  }

  # AFD filters
  class { 'lma_collector::afd::api': }
  class { 'lma_collector::afd::workers': }

}

$alerting_mode = $lma_collector['alerting_mode']
if $alerting_mode != 'disabled' {

  $deployment_id = hiera('deployment_id')
  if $alerting_mode == 'remote' {
    $use_nagios = true
    $nagios_url = $lma_collector['nagios_url']
    $nagios_user = $lma_collector['nagios_user']
    $nagios_password = $lma_collector['nagios_password']
  } elsif $alerting_mode == 'local' {
    $use_nagios = true
    $lma_infra_alerting = hiera_hash('lma_infrastructure_alerting', false)
    $nagios_nodes = filter_nodes(hiera('nodes'), 'role', 'infrastructure_alerting')
    $nagios_server = $nagios_nodes[0]['internal_address']
    $nagios_user = $lma_infra_alerting['nagios_user']
    $nagios_password = $lma_infra_alerting['nagios_password']

    # Important: $http_port and $http_path must match the
    # lma_infra_monitoring configuration.
    $http_port = $lma_collector::params::nagios_http_port
    $http_path = $lma_collector::params::nagios_http_path
    $nagios_url = "http://${nagios_server}:${http_port}/${http_path}"
  } elsif $alerting_mode == 'standalone' {
    $use_nagios = false
    $subject = "${lma_collector::params::smtp_subject} environment ${deployment_id}"
    class { 'lma_collector::smtp_alert':
      send_from => $lma_collector['alerting_send_from'],
      send_to   => [$lma_collector['alerting_send_to']],
      subject   => $subject,
      host      => $lma_collector['alerting_smtp_host'],
      auth      => $lma_collector['alerting_smtp_auth'],
      user      => $lma_collector['alerting_smtp_user'],
      password  => $lma_collector['alerting_smtp_password'],
    }
  } else {
    fail("'${alerting_mode}' mode not supported for the infrastructure alerting service")
  }

  if $use_nagios {
    lma_collector::gse_nagios { 'global_clusters':
      openstack_deployment_name => $deployment_id,
      url                       => $nagios_url,
      user                      => $nagios_user,
      password                  => $nagios_password,
      message_type              => $lma_collector['gse_cluster_global']['output_message_type'],
      virtual_hostname          => $lma_collector::params::nagios_hostname_for_cluster_global,
    }

    lma_collector::gse_nagios { 'node_clusters':
      openstack_deployment_name => $deployment_id,
      url                       => $nagios_url,
      user                      => $nagios_user,
      password                  => $nagios_password,
      message_type              => $lma_collector['gse_cluster_node']['output_message_type'],
      virtual_hostname          => $lma_collector::params::nagios_hostname_for_cluster_nodes,
    }
  }
}
