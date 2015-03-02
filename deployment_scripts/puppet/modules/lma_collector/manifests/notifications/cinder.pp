class lma_collector::notifications::cinder (
    $topics = [],
    $driver = $lma_collector::params::notification_driver,
) inherits lma_collector::params {

  validate_array($topics)

  include cinder::params

  cinder_config {
    'DEFAULT/notification_topics': value => join($topics, ','),
    notify => Service[$::cinder::params::volume_service],
  }
  cinder_config {
    'DEFAULT/notification_driver': value => $driver,
    notify => Service[$::cinder::params::volume_service],
  }

  service { $::cinder::params::volume_service:
  }
}
