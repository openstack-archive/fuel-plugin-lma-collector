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

# Logs
class { 'lma_collector::logs::openstack': }

class { 'lma_collector::logs::mysql': }

class { 'lma_collector::logs::rabbitmq': }

if $fuel_settings['deployment_mode'] =~ /^ha/ {
  class { 'lma_collector::logs::pacemaker': }
}

# Notifications
if $fuel_settings['rabbit']['user'] {
  $rabbitmq_user = $fuel_settings['rabbit']['user']
}
else {
  $rabbitmq_user = 'nova'
}

if $enable_notifications {
  class { 'lma_collector::notifications::controller':
    host     => $fuel_settings['management_vip'],
    user     => $rabbitmq_user,
    password => $fuel_settings['rabbit']['password'],
    topics   => $notification_topics,
  }
}
