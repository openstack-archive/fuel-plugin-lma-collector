class lma_collector::notifications::controller (
    $host = $lma_collector::params::rabbitmq_host,
    $port = $lma_collector::params::rabbitmq_port,
    $user = $lma_collector::params::rabbitmq_user,
    $password = $lma_collector::params::rabbitmq_password,
    $driver = $lma_collector::params::notification_driver,
    $topics = [],
) inherits lma_collector::params {

  include lma_collector::service

  validate_array($topics)
  $notification_topics = join($topics, ',')

  # We need to pick one exchange and we settled on 'nova'. The default
  # exchange ("") doesn't work because Heka would fail to create the queue in
  # case it doesn't exist yet.
  $exchange = 'nova'

  heka::decoder::sandbox { 'notification':
    config_dir => $lma_collector::params::config_dir,
    filename   => "${lma_collector::params::plugins_dir}/decoders/notification.lua" ,
    config     => {
      include_full_notification => false
    },
    notify     => Class['lma_collector::service'],
  }

  heka::input::amqp { 'openstack_info':
    config_dir           => $lma_collector::params::config_dir,
    decoder              => 'notification',
    user                 => $user,
    password             => $password,
    host                 => $host,
    port                 => $port,
    exchange             => $exchange,
    exchange_durability  => false,
    exchange_auto_delete => false,
    queue_auto_delete    => false,
    exchange_type        => 'topic',
    queue                => "${lma_collector::params::lma_topic}.info",
    routing_key          => "${lma_collector::params::lma_topic}.info",
    notify               => Class['lma_collector::service'],
  }

  heka::input::amqp { 'openstack_error':
    config_dir           => $lma_collector::params::config_dir,
    decoder              => 'notification',
    user                 => $user,
    password             => $password,
    host                 => $host,
    port                 => $port,
    exchange             => $exchange,
    exchange_durability  => false,
    exchange_auto_delete => false,
    queue_auto_delete    => false,
    exchange_type        => 'topic',
    queue                => "${lma_collector::params::lma_topic}.error",
    routing_key          => "${lma_collector::params::lma_topic}.error",
    notify               => Class['lma_collector::service'],
  }

  heka::input::amqp { 'openstack_warn':
    config_dir           => $lma_collector::params::config_dir,
    decoder              => 'notification',
    user                 => $user,
    password             => $password,
    host                 => $host,
    port                 => $port,
    exchange             => $exchange,
    exchange_durability  => false,
    exchange_auto_delete => false,
    queue_auto_delete    => false,
    exchange_type        => 'topic',
    queue                => "${lma_collector::params::lma_topic}.warn",
    routing_key          => "${lma_collector::params::lma_topic}.warn",
    notify               => Class['lma_collector::service'],
  }

  # Nova
  include nova::params

  nova_config {
    'DEFAULT/notification_topics': value => $notification_topics,
    notify => Service[$::nova::params::api_service_name, $::nova::params::conductor_service_name, $::nova::params::scheduler_service_name],
  }
  nova_config {
    'DEFAULT/notification_driver': value => $driver,
    notify => Service[$::nova::params::api_service_name, $::nova::params::conductor_service_name, $::nova::params::scheduler_service_name],
  }

  service { [$::nova::params::api_service_name, $::nova::params::conductor_service_name, $::nova::params::scheduler_service_name]:
    hasstatus  => true,
    hasrestart => true,
  }

  # Cinder
  include cinder::params

  cinder_config {
    'DEFAULT/notification_topics': value => $notification_topics,
    notify => Service[$::cinder::params::api_service, $::cinder::params::scheduler_service],
  }
  cinder_config {
    'DEFAULT/notification_driver': value => $driver,
    notify => Service[$::cinder::params::api_service, $::cinder::params::scheduler_service],
  }

  service { [$::cinder::params::api_service, $::cinder::params::scheduler_service]:
    hasstatus  => true,
    hasrestart => true,
  }

  # Keystone
  include keystone::params

  keystone_config {
    'DEFAULT/notification_topics': value => $notification_topics,
    notify => Service[$::keystone::params::service_name],
  }
  keystone_config {
    'DEFAULT/notification_driver': value => $driver,
    notify => Service[$::keystone::params::service_name],
  }

  service { $::keystone::params::service_name:
    hasstatus  => true,
    hasrestart => true,
  }

  # Neutron
  include neutron::params

  neutron_config {
    'DEFAULT/notification_topics': value => $notification_topics,
    notify => Service[$::neutron::params::server_service],
  }
  neutron_config {
    'DEFAULT/notification_driver': value => $driver,
    notify => Service[$::neutron::params::server_service],
  }

  service { $::neutron::params::server_service:
    hasstatus  => true,
    hasrestart => true,
  }

  # Glance
  include glance::params

  # Default value is 'image.localhost' for Glance
  $glance_publisher_id = "image.${::hostname}"

  glance_api_config {
    'DEFAULT/notification_topics': value => $notification_topics,
    notify => Service[$::glance::params::api_service_name],
  }
  glance_api_config {
    'DEFAULT/notification_driver': value => $driver,
    notify => Service[$::glance::params::api_service_name],
  }
  glance_api_config {
    'DEFAULT/default_publisher_id': value => $glance_publisher_id,
    notify => Service[$::glance::params::api_service_name],
  }
  glance_registry_config {
    'DEFAULT/notification_topics': value => $notification_topics,
    notify => Service[$::glance::params::registry_service_name],
  }
  glance_registry_config {
    'DEFAULT/notification_driver': value => $driver,
    notify => Service[$::glance::params::registry_service_name],
  }
  glance_registry_config {
    'DEFAULT/default_publisher_id': value => $glance_publisher_id,
    notify => Service[$::glance::params::registry_service_name],
  }

  service { [$::glance::params::api_service_name, $::glance::params::registry_service_name]:
    hasstatus  => true,
    hasrestart => true,
  }

  # Heat
  include heat::params

  heat_config {
    'DEFAULT/notification_topics': value => $notification_topics,
    notify => Service[$::heat::params::api_service_name, $::heat::params::engine_service_name],
  }
  heat_config {
    'DEFAULT/notification_driver': value => $driver,
    notify => Service[$::heat::params::api_service_name, $::heat::params::engine_service_name],
  }

  service { [$::heat::params::api_service_name, $::heat::params::engine_service_name]:
    hasstatus  => true,
    hasrestart => true,
  }
}
