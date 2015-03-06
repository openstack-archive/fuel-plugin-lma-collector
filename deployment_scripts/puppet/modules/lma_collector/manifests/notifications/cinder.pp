class lma_collector::notifications::cinder (
    $topics = [],
    $driver = $lma_collector::params::notification_driver,
) inherits lma_collector::params {

  include lma_collector::service

  validate_array($topics)

  include cinder::params

  cinder_config {
    'DEFAULT/notification_topics': value => join($topics, ','),
    notify => Class['lma_collector::service'],
  }
  cinder_config {
    'DEFAULT/notification_driver': value => $driver,
    notify => Class['lma_collector::service'],
  }

  service { $::cinder::params::volume_service:
  }
}
