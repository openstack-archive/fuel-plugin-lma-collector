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

notice('fuel-plugin-lma-collector: controller.pp')

prepare_network_config(hiera_hash('network_scheme', {}))
$messaging_address = get_network_role_property('mgmt/messaging', 'ipaddr')
$memcache_address  = get_network_role_property('mgmt/memcache', 'ipaddr')
$network_metadata = hiera_hash('network_metadata')

$ceilometer      = hiera_hash('ceilometer', {})
$lma_collector   = hiera_hash('lma_collector')
$rabbit          = hiera_hash('rabbit')
$management_vip  = hiera('management_vip')
$storage_options = hiera_hash('storage', {})
$murano          = hiera_hash('murano')
$sahara          = hiera_hash('sahara')
$contrail        = hiera('contrail', false)
$detach_rabbitmq = hiera('detach-rabbitmq', {})

$detach_rabbitmq_enabled = $detach_rabbitmq['metadata'] and $detach_rabbitmq['metadata']['enabled']

if $ceilometer['enabled'] {
  $notification_topics = ['notifications', 'lma_notifications']
}
else {
  $notification_topics = ['lma_notifications']
}

if $rabbit['user'] {
  $rabbitmq_user = $rabbit['user']
}
else {
  $rabbitmq_user = 'nova'
}

# Make sure the Log and Metric collector services are configured with the
# "pacemaker" provider
Service<| title == 'log_collector' |> {
  provider => 'pacemaker'
}
Service<| title == 'metric_collector' |> {
  provider => 'pacemaker'
}

# Sahara notifications
if $sahara['enabled'] {
  include sahara::params
  $sahara_api_service    = $::sahara::params::api_service_name
  $sahara_engine_service = $::sahara::params::engine_service_name

  sahara_config { 'DEFAULT/enable_notifications':
    value  => true,
    notify => Service[$sahara_api_service, $sahara_engine_service],
  }
  sahara_config { 'DEFAULT/notification_topics':
    value  => $notification_topics,
    notify => Service[$sahara_api_service, $sahara_engine_service],
  }
  sahara_config { 'DEFAULT/notification_driver':
    value  => 'messaging',
    notify => Service[$sahara_api_service, $sahara_engine_service],
  }

  service { [$sahara_api_service, $sahara_engine_service]:
    hasstatus  => true,
    hasrestart => true,
  }
}

# Nova notifications
include nova::params
$nova_api_service       = $::nova::params::api_service_name
$nova_conductor_service = $::nova::params::conductor_service_name
$nova_scheduler_service = $::nova::params::scheduler_service_name

nova_config { 'DEFAULT/notification_topics':
  value  => $notification_topics,
  notify => Service[$nova_api_service, $nova_conductor_service, $nova_scheduler_service],
}
nova_config { 'DEFAULT/notification_driver':
  value  => 'messaging',
  notify => Service[$nova_api_service, $nova_conductor_service, $nova_scheduler_service],
}
nova_config { 'DEFAULT/notify_on_state_change':
  value  => 'vm_and_task_state',
  notify => Service[$nova_api_service, $nova_conductor_service, $nova_scheduler_service],
}

service { [$nova_api_service, $nova_conductor_service, $nova_scheduler_service]:
  hasstatus  => true,
  hasrestart => true,
}

# Cinder notifications
include cinder::params
$cinder_api_service       = $::cinder::params::api_service
$cinder_scheduler_service = $::cinder::params::scheduler_service
$cinder_volume_service    = $::cinder::params::volume_service

if $storage_options['volumes_ceph'] {
  # In this case, cinder-volume runs on controller node
  $cinder_services = [$cinder_api_service, $cinder_scheduler_service, $cinder_volume_service]
} else {
  $cinder_services = [$cinder_api_service, $cinder_scheduler_service]
}

cinder_config { 'DEFAULT/notification_topics':
  value  => $notification_topics,
  notify => Service[$cinder_services],
}
cinder_config { 'DEFAULT/notification_driver':
  value  => 'messaging',
  notify => Service[$cinder_services],
}

service { $cinder_services:
  hasstatus  => true,
  hasrestart => true,
}

# Keystone notifications
# Keystone is executed as a WSGI application inside Apache so the Apache
# service needs to be restarted if necessary
include apache::params
include apache::service

keystone_config { 'DEFAULT/notification_topics':
  value  => $notification_topics,
  notify => Class['apache::service'],
}
keystone_config { 'DEFAULT/notification_driver':
  value  => 'messaging',
  notify => Class['apache::service'],
}

# Neutron notifications
include neutron::params

neutron_config { 'DEFAULT/notification_topics':
  value  => $notification_topics,
  notify => Service[$::neutron::params::server_service],
}
neutron_config { 'DEFAULT/notification_driver':
  value  => 'messaging',
  notify => Service[$::neutron::params::server_service],
}

service { $::neutron::params::server_service:
  hasstatus  => true,
  hasrestart => true,
}

# Glance notifications
include glance::params

$glance_api_service = $::glance::params::api_service_name
$glance_registry_service = $::glance::params::registry_service_name

# Default value is 'image.localhost' for Glance
$glance_publisher_id = "image.${::hostname}"

glance_api_config { 'DEFAULT/notification_topics':
  value  => $notification_topics,
  notify => Service[$glance_api_service],
}
glance_api_config { 'DEFAULT/notification_driver':
  value  => 'messaging',
  notify => Service[$glance_api_service],
}
glance_api_config { 'DEFAULT/default_publisher_id':
  value  => $glance_publisher_id,
  notify => Service[$glance_api_service],
}
glance_registry_config { 'DEFAULT/notification_topics':
  value  => $notification_topics,
  notify => Service[$glance_registry_service],
}
glance_registry_config { 'DEFAULT/notification_driver':
  value  => 'messaging',
  notify => Service[$glance_registry_service],
}
glance_registry_config { 'DEFAULT/default_publisher_id':
  value  => $glance_publisher_id,
  notify => Service[$glance_registry_service],
}

service { [$glance_api_service, $glance_registry_service]:
  hasstatus  => true,
  hasrestart => true,
}

# Heat notifications
include heat::params

$heat_api_service    = $::heat::params::api_service_name
$heat_engine_service = $::heat::params::engine_service_name

heat_config { 'DEFAULT/notification_topics':
  value  => $notification_topics,
  notify => Service[$heat_api_service, $heat_engine_service],
}
heat_config { 'DEFAULT/notification_driver':
  value  => $driver,
  notify => Service[$heat_api_service, $heat_engine_service],
}

service { $heat_api_service:
  hasstatus  => true,
  hasrestart => true,
}

# The heat-engine service is managed by Pacemaker.
service { $heat_engine_service:
  hasstatus  => true,
  hasrestart => true,
  provider   => 'pacemaker',
}

# OpenStack logs are useful for deriving HTTP metrics, so we enable them even
# if Elasticsearch is disabled.
lma_collector::logs::openstack { 'nova': }

# For every virtual network that exists, Neutron spawns one metadata proxy
# service that will log to a separate file in the Neutron log directory.
# Eventually it may be hundreds of these files and Heka will have trouble
# coping with the situation. See bug #1547402 for details.
lma_collector::logs::openstack { 'neutron':
  service_match => '(dhcp-agent|l3-agent|metadata-agent|neutron-netns-cleanup|openvswitch-agent|server)',
}
lma_collector::logs::openstack { 'cinder': }
lma_collector::logs::openstack { 'glance': }
lma_collector::logs::openstack { 'heat': }
lma_collector::logs::openstack { 'keystone': }
class {'lma_collector::logs::keystone_wsgi': }
lma_collector::logs::openstack { 'horizon': }

if $murano['enabled'] {
  lma_collector::logs::openstack { 'murano': }
}

if $sahara['enabled'] {
  lma_collector::logs::openstack { 'sahara': }
}

if ! $storage_options['objects_ceph'] {
  class { 'lma_collector::logs::swift':
    file_match => 'swift-all\.log\.?(?P<Seq>\d*)$',
    priority   => '["^Seq"]',
  }
}

if hiera('lma::collector::elasticsearch::server', false) {
  class { 'lma_collector::logs::pacemaker': }
}

# Metrics
if hiera('lma::collector::influxdb::server', false) {

  $nova           = hiera_hash('nova', {})
  $neutron        = hiera_hash('quantum_settings', {})
  $cinder         = hiera_hash('cinder', {})
  $haproxy_socket = '/var/lib/haproxy/stats'

  if $storage_options['volumes_ceph'] or $storage_options['images_ceph'] or
      $storage_options['objects_ceph'] or $storage_options['ephemeral_ceph']{
    $ceph_enabled = true
  } else {
    $ceph_enabled = false
  }

  class { 'lma_collector::logs::counter':
    hostname => $::hostname,
  }

  class { 'lma_collector::collectd::base':
    processes    => ['hekad', 'collectd'],
    # collectd plugins on controller do many network I/O operations, so
    # it is recommended to increase this value
    read_threads => 10,
  }

  # All collectd Python plugins must be configured in the same manifest.
  # This limitation is imposed by the upstream collectd Puppet module.
  # That's why we declare the RabbitMQ plugin if it is running on the
  # controller.
  unless $detach_rabbitmq_enabled {
    class { 'lma_collector::collectd::rabbitmq':
      queue => ['/^(\\w*notifications\\.(error|info|warn)|[a-z]+|(metering|event)\.sample)$/'],
    }
  }

  $pacemaker_master_resource = 'vip__management'

  class { 'lma_collector::collectd::pacemaker':
    resources       => [
      'vip__public',
      'vip__management',
      'vip__vrouter_pub',
      'vip__vrouter',
    ],
    master_resource => $pacemaker_master_resource,
    hostname        => $::fqdn,
  }

  $openstack_service_config = {
    user                      => 'nova',
    password                  => $nova['user_password'],
    tenant                    => 'services',
    keystone_url              => "http://${management_vip}:5000/v2.0",
    pacemaker_master_resource => $pacemaker_master_resource,
  }
  $openstack_services = {
    'nova'     => $openstack_service_config,
    'cinder'   => $openstack_service_config,
    'glance'   => $openstack_service_config,
    'keystone' => $openstack_service_config,
    'neutron'  => $openstack_service_config,
  }
  create_resources(lma_collector::collectd::openstack, $openstack_services)

  # FIXME(elemoine) use the special attribute * when Fuel uses a Puppet version
  # that supports it.
  class { 'lma_collector::collectd::openstack_checks':
    user                      => $openstack_service_config[user],
    password                  => $openstack_service_config[password],
    tenant                    => $openstack_service_config[tenant],
    keystone_url              => $openstack_service_config[keystone_url],
    pacemaker_master_resource => $openstack_service_config[pacemaker_master_resource],
  }

  # FIXME(elemoine) use the special attribute * when Fuel uses a Puppet version
  # that supports it.
  class { 'lma_collector::collectd::hypervisor':
    user                      => $openstack_service_config[user],
    password                  => $openstack_service_config[password],
    tenant                    => $openstack_service_config[tenant],
    keystone_url              => $openstack_service_config[keystone_url],
    pacemaker_master_resource => $openstack_service_config[pacemaker_master_resource],
    # Fuel sets cpu_allocation_ratio to 8.0 in nova.conf
    cpu_allocation_ratio      => 8.0,
  }

  class { 'lma_collector::collectd::haproxy':
    socket       => $haproxy_socket,
    # Ignore internal stats ('Stats' for 6.1, 'stats' for 7.0) and lma proxies
    proxy_ignore => ['Stats', 'stats', 'lma'],
    proxy_names  => {
      'ceilometer'          => 'ceilometer-api',
      'cinder-api'          => 'cinder-api',
      'glance-api'          => 'glance-api',
      'glance-registry'     => 'glance-registry-api',
      'heat-api'            => 'heat-api',
      'heat-api-cfn'        => 'heat-cfn-api',
      'heat-api-cloudwatch' => 'heat-cloudwatch-api',
      'horizon'             => 'horizon-web',
      'horizon-ssl'         => 'horizon-https',
      'keystone-1'          => 'keystone-public-api',
      'keystone-2'          => 'keystone-admin-api',
      'murano'              => 'murano-api',
      'mysqld'              => 'mysqld-tcp',
      'neutron'             => 'neutron-api',
      'nova-api-1'          => 'nova-ec2-api',
      'nova-api-2'          => 'nova-api',
      'nova-novncproxy'     => 'nova-novncproxy-websocket',
      'nova-metadata-api'   => 'nova-metadata-api',
      'sahara'              => 'sahara-api',
      'swift'               => 'swift-api',
    },
  }

  if $ceph_enabled {
    class { 'lma_collector::collectd::ceph_mon': }
  }

  class { 'lma_collector::collectd::memcached':
    host => $memcache_address,
  }

  class { 'lma_collector::collectd::apache': }

  # TODO(all): This class is still called to ensure the sandbox deletion
  # when upgrading the plugin. Can be removed for next release after 0.10.0.
  class { 'lma_collector::logs::http_metrics': }

  class { 'lma_collector::logs::aggregated_http_metrics': }

  # Notification are always collected, lets extract metrics from there
  class { 'lma_collector::notifications::metrics': }

  # Enable the Apache status module
  class { 'fuel_lma_collector::mod_status': }

  # Enable service heartbeat metrics
  class { 'lma_collector::metrics::service_heartbeat':
    services => ['haproxy', 'memcached']
  }

  # AFD filters
  class { 'lma_collector::afd::api': }
  class { 'lma_collector::afd::workers': }

  # VIP checks
  if hiera('lma::collector::influxdb::server', false) {
    $influxdb_server = hiera('lma::collector::influxdb::server')
    $influxdb_port = hiera('lma::collector::influxdb::port')
    $influxdb_url = "http://${influxdb_server}:${influxdb_port}/ping"
  }

  $vip_urls = {
    'influxdb' => $influxdb_url,
  }
  $expected_codes = {
    'influxdb' => 204,
  }

  class { 'lma_collector::collectd::http_check':
    urls                      => delete_undef_values($vip_urls),
    expected_codes            => $expected_codes,
    timeout                   => 1,
    max_retries               => 3,
    pacemaker_master_resource => $pacemaker_master_resource,
  }
}

$alerting_mode = $lma_collector['alerting_mode']
$deployment_id = hiera('deployment_id')

if $alerting_mode == 'standalone' {
  $subject = "LMA Alert Notification - environment ${deployment_id}"
  class { 'lma_collector::smtp_alert':
    send_from => $lma_collector['alerting_send_from'],
    send_to   => [$lma_collector['alerting_send_to']],
    subject   => $subject,
    host      => $lma_collector['alerting_smtp_host'],
    auth      => $lma_collector['alerting_smtp_auth'],
    user      => $lma_collector['alerting_smtp_user'],
    password  => $lma_collector['alerting_smtp_password'],
  }
}

if hiera('lma::collector::infrastructure_alerting::server', false) {
  lma_collector::gse_nagios { 'global_clusters':
    openstack_deployment_name => $deployment_id,
    server                    => hiera('lma::collector::infrastructure_alerting::server'),
    http_port                 => hiera('lma::collector::infrastructure_alerting::http_port'),
    http_path                 => hiera('lma::collector::infrastructure_alerting::http_path'),
    user                      => hiera('lma::collector::infrastructure_alerting::user'),
    password                  => hiera('lma::collector::infrastructure_alerting::password'),
    message_type              => $lma_collector['gse_cluster_global']['output_message_type'],
    # Following parameter must match the lma_infrastructure_alerting::params::nagios_global_vhostname_prefix
    virtual_hostname          => '00-global-clusters',
  }

  lma_collector::gse_nagios { 'node_clusters':
    openstack_deployment_name => $deployment_id,
    server                    => hiera('lma::collector::infrastructure_alerting::server'),
    http_port                 => hiera('lma::collector::infrastructure_alerting::http_port'),
    http_path                 => hiera('lma::collector::infrastructure_alerting::http_path'),
    user                      => hiera('lma::collector::infrastructure_alerting::user'),
    password                  => hiera('lma::collector::infrastructure_alerting::password'),
    message_type              => $lma_collector['gse_cluster_node']['output_message_type'],
    # Following parameter must match the lma_infrastructure_alerting::params::nagios_node_vhostname_prefix
    virtual_hostname          => '00-node-clusters',
  }
}
