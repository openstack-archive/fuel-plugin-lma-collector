include lma_collector::params

$ceilometer    = hiera('ceilometer')
$lma_collector = hiera('lma_collector')

$enable_notifications = $lma_collector['enable_notifications']
if $ceilometer['enabled'] {
  $notification_topics = [$lma_collector::params::openstack_topic, $lma_collector::params::lma_topic]
}
else {
  $notification_topics = [$lma_collector::params::lma_topic]
}

class { 'lma_collector::logs::openstack': }

if $enable_notifications {
  class { 'lma_collector::notifications::cinder':
    topics  => $notification_topics,
  }
}
