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
}
else {
  $rabbitmq_user = 'nova'
}

if hiera('deployment_mode') =~ /^ha_/ {
  $ha_deployment = true
}else{
  $ha_deployment = false
}

if $ha_deployment {
  $rabbitmq_pid_file = '/var/run/rabbitmq/p_pid'
}
else {
  $rabbitmq_pid_file = '/var/run/rabbitmq/pid'
}

# Logs
class { 'lma_collector::logs::openstack': }

class { 'lma_collector::logs::mysql': }

class { 'lma_collector::logs::rabbitmq': }

if $ha_deployment {
  class { 'lma_collector::logs::pacemaker': }
}

# Notifications
if $enable_notifications {
  class { 'lma_collector::notifications::controller':
    host     => '127.0.0.1',
    port     => hiera('amqp_port', '5673'),
    user     => $rabbitmq_user,
    password => $fuel_settings['rabbit']['password'],
    topics   => $notification_topics,
  }
}

# Metrics
if $fuel_settings['lma_collector']['influxdb_mode'] != 'disabled' {

  if $ha_deployment {
    $haproxy_socket = '/var/lib/haproxy/stats'
  }else{
    # do not deploy HAproxy collectd plugin
    $haproxy_socket = undef
  }

  $storage_options = hiera('storage', {})
  if $storage_options['volumes_ceph'] or $storage_options['images_ceph'] or $storage_options['objects_ceph'] or $storage_options['ephemeral_ceph']{
    $ceph_enabled = true
  } else {
    $ceph_enabled = false
  }

  class { 'lma_collector::collectd::controller':
    service_user      => 'nova',
    service_password  => $fuel_settings['nova']['user_password'],
    service_tenant    => 'services',
    keystone_url      => "http://${management_vip}:5000/v2.0",
    rabbitmq_pid_file => $rabbitmq_pid_file,
    haproxy_socket    => $haproxy_socket,
    ceph_enabled      => $ceph_enabled,
  }

  class { 'lma_collector::collectd::mysql':
    username => 'nova',
    password => $fuel_settings['nova']['db_password'],
  }

  class { 'lma_collector::logs::metrics': }

  if $enable_notifications {
    class { 'lma_collector::notifications::metrics': }
  }

  # Enable Apache status module
  class { 'lma_collector::mod_status': }

  # Enable pacemaker resource location metrics
  if $ha_deployment {
    class { 'lma_collector::metrics::pacemaker_resources': }
  }
}
