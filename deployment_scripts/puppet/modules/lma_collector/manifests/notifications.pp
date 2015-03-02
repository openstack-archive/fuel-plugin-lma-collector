class lma_collector::notifications (
    $host = $lma_collector::params::rabbitmq_host,
    $user = $lma_collector::params::rabbitmq_user,
    $password = $lma_collector::params::rabbitmq_password,
    $exchange = $lma_collector::params::rabbitmq_exchange,
) {
  include lma_collector::params

  heka::decoder::sandbox { 'notification':
    config_dir => $lma_collector::params::config_dir,
    filename   => "${lma_collector::plugins_dir}/decoders/notification.lua" ,
    config     => {
      include_full_notification => false
    },
    notify     => Service[$lma_collector::params::service_name],
  }

  heka::input::amqp { 'openstack_info':
    config_dir           => $lma_collector::params::config_dir,
    decoder              => 'notification',
    user                 => $user,
    password             => $password,
    host                 => $host,
    exchange             => $exchange,
    exchange_durability  => false,
    exchange_auto_delete => false,
    queue_auto_delete    => false,
    exchange_type        => "topic",
    queue                => "${lma_collector::params::notification_topic}.info",
    routing_key          => "${lma_collector::params::notification_topic}.info",
    notify               => Service[$lma_collector::params::service_name],
  }

  heka::input::amqp { 'openstack_error':
    config_dir           => $lma_collector::params::config_dir,
    decoder              => 'notification',
    user                 => $user,
    password             => $password,
    host                 => $host,
    exchange             => $exchange,
    exchange_durability  => false,
    exchange_auto_delete => false,
    queue_auto_delete    => false,
    exchange_type        => "topic",
    queue                => "${lma_collector::params::notification_topic}.error",
    routing_key          => "${lma_collector::params::notification_topic}.error",
    notify               => Service[$lma_collector::params::service_name],
  }

  heka::input::amqp { 'openstack_warn':
    config_dir           => $lma_collector::params::config_dir,
    decoder              => 'notification',
    user                 => $user,
    password             => $password,
    host                 => $host,
    exchange             => $exchange,
    exchange_durability  => false,
    exchange_auto_delete => false,
    queue_auto_delete    => false,
    exchange_type        => "topic",
    queue                => "${lma_collector::params::notification_topic}.warn",
    routing_key          => "${lma_collector::params::notification_topic}.warn",
    notify               => Service[$lma_collector::params::service_name],
  }
}
