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

$ceilometer      = hiera_hash('ceilometer', {})
$lma_collector   = hiera_hash('lma_collector')
$rabbit          = hiera_hash('rabbit')
$storage_options = hiera_hash('storage', {})
$murano          = hiera_hash('murano')
$sahara          = hiera_hash('sahara')

if $ceilometer['enabled'] {
  $notification_topics = ['notifications', 'lma_notifications']
}
else {
  $notification_topics = ['lma_notifications']
}

# Make sure the Log and Metric collector services are configured with the
# "pacemaker" provider
Service<| title == 'log_collector' |> {
  provider => 'pacemaker'
}
Service<| title == 'metric_collector' |> {
  provider => 'pacemaker'
}

# OpenStack logs and notifications are useful for deriving metrics, so we enable
# them even if Elasticsearch is disabled.
if hiera('lma::collector::elasticsearch::server', false) or hiera('lma::collector::influxdb::server', false){
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

  # Enable pagination for Neutron
  neutron_config { 'DEFAULT/allow_pagination':
    value  => true,
    notify => Service[$::neutron::params::server_service],
  }
  neutron_config { 'DEFAULT/pagination_max_limit':
    value  => '100',
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
    value  => 'messaging',
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

  class { 'lma_collector::logs::pacemaker': }
}

# Metrics
if hiera('lma::collector::influxdb::server', false) {
  class { 'lma_collector::logs::counter':
    hostname => $::hostname,
  }

  # TODO(all): This class is still called to ensure the sandbox deletion
  # when upgrading the plugin. Can be removed for next release after 0.10.0.
  class { 'lma_collector::logs::http_metrics': }

  class { 'lma_collector::logs::aggregated_http_metrics': }
}

if hiera('lma::collector::infrastructure_alerting::server', false) {
  $deployment_id = hiera('deployment_id')

  lma_collector::gse_nagios { 'global':
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

  lma_collector::gse_nagios { 'nodes':
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

  # Purge remaining files from previous 0.10.x version
  $toml_metric_collector_to_purge = prefix([
    'filter-afd_api_backends.toml', 'filter-afd_api_endpoints.toml',
    'filter-afd_service_rabbitmq_disk.toml',
    'filter-afd_service_rabbitmq_memory.toml',
    'filter-afd_service_rabbitmq_queue.toml',
    'filter-afd_workers.toml',
    'filter-service_heartbeat.toml',
    'encoder-nagios_gse_global_clusters.toml',
    'encoder-nagios_gse_node_clusters.toml',
    'output-nagios_gse_global_clusters.toml',
    'output-nagios_gse_node_clusters.toml',
  ], '/etc/metric_collector/')

  file { $toml_metric_collector_to_purge:
    ensure => absent,
  } ->
  lma_collector::gse_nagios { 'services':
    openstack_deployment_name => $deployment_id,
    server                    => hiera('lma::collector::infrastructure_alerting::server'),
    http_port                 => hiera('lma::collector::infrastructure_alerting::http_port'),
    http_path                 => hiera('lma::collector::infrastructure_alerting::http_path'),
    user                      => hiera('lma::collector::infrastructure_alerting::user'),
    password                  => hiera('lma::collector::infrastructure_alerting::password'),
    message_type              => $lma_collector['gse_cluster_service']['output_message_type'],
    # Following parameter must match the lma_infrastructure_alerting::params::nagios_node_vhostname_prefix
    virtual_hostname          => '00-service-clusters',
  }
}
