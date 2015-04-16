class lma_collector::notifications::compute (
    $topics = [],
    $driver = $lma_collector::params::notification_driver,
) inherits lma_collector::params {
  include lma_collector::service

  validate_array($topics)

  include nova::params

  nova_config {
    'DEFAULT/notification_topics': value => join($topics, ','),
    notify => Service[$::nova::params::compute_service_name],
  }
  nova_config {
    'DEFAULT/notification_driver': value => $driver,
    notify => Service[$::nova::params::compute_service_name],
  }

  service { $::nova::params::compute_service_name:
    hasstatus  => true,
    hasrestart => true,
  }
}
