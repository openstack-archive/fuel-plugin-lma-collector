class lma_collector::notifications::compute (
    $topics = [],
    $driver = $lma_collector::params::notification_driver,
) inherits lma_collector::params {
  include lma_collector::service

  validate_array($topics)

  include nova::params

  nova_config {
    'DEFAULT/notification_topics': value => join($topics, ','),
    notify => Class['lma_collector::service'],
  }
  nova_config {
    'DEFAULT/notification_driver': value => $driver,
    notify => Class['lma_collector::service'],
  }

  service { $::nova::params::compute_service_name:
  }
}
