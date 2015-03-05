# TODO(spasquier): replace by Hiera when testing with 6.1
$fuel_settings = parseyaml(file('/etc/astute.yaml'))

include lma_collector::params

$enable_notifications = $fuel_settings['lma_collector']['enable_notifications']
if $fuel_settings['ceilometer']['enabled'] {
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
