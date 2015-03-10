# TODO(spasquier): replace by Hiera when testing with 6.1
$fuel_settings = parseyaml(file('/etc/astute.yaml'))

include lma_collector::params

$management_vip = $fuel_settings['management_vip']

$enable_notifications = $fuel_settings['lma_collector']['enable_notifications']
if $fuel_settings['ceilometer']['enabled'] {
  $notification_topics = [$lma_collector::params::openstack_topic, $lma_collector::params::lma_topic]
}
else {
  $notification_topics = [$lma_collector::params::lma_topic]
}

if $fuel_settings['rabbit']['user'] {
  $rabbitmq_user = $fuel_settings['rabbit']['user']
  $rabbitmq_pid_file = '/var/run/rabbitmq/p_pid'
}
else {
  $rabbitmq_user = 'nova'
  $rabbitmq_pid_file = '/var/run/rabbitmq/pid'
}

# Logs
class { 'lma_collector::logs::openstack': }

class { 'lma_collector::logs::mysql': }

class { 'lma_collector::logs::rabbitmq': }

if $fuel_settings['deployment_mode'] =~ /^ha/ {
  class { 'lma_collector::logs::pacemaker': }
}

# Notifications
if $enable_notifications {
  class { 'lma_collector::notifications::controller':
    host     => $fuel_settings['management_vip'],
    user     => $rabbitmq_user,
    password => $fuel_settings['rabbit']['password'],
    topics   => $notification_topics,
  }
}

# Metrics
class { 'lma_collector::collectd::controller':
  service_user      => 'nova',
  service_password  => $fuel_settings['nova']['user_password'],
  service_tenant    => 'services',
  keystone_url      => "http://${management_vip}:5000/v2.0",
  rabbitmq_pid_file => $lma_collector::params::rabbitmq_pid_file,
}
