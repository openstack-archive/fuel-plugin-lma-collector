include lma_collector::params

$ceilometer     = hiera('ceilometer')
$lma_collector  = hiera('lma_collector')
$management_vip = hiera('management_vip')
$nova           = hiera('nova')
$cinder         = hiera('cinder')
$rabbit         = hiera('rabbit')
$neutron        = hiera('quantum_settings')

$enable_notifications = $lma_collector['enable_notifications']
if $ceilometer['enabled'] {
  $notification_topics = [$lma_collector::params::openstack_topic, $lma_collector::params::lma_topic]
}
else {
  $notification_topics = [$lma_collector::params::lma_topic]
}

if $rabbit['user'] {
  $rabbitmq_user = $rabbit['user']
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
    password => $rabbit['password'],
    topics   => $notification_topics,
  }
}

# Metrics
if $lma_collector['influxdb_mode'] != 'disabled' {

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
    service_password  => $nova['user_password'],
    service_tenant    => 'services',
    keystone_url      => "http://${management_vip}:5000/v2.0",
    rabbitmq_pid_file => $rabbitmq_pid_file,
    haproxy_socket    => $haproxy_socket,
    ceph_enabled      => $ceph_enabled,
  }

  class { 'lma_collector::collectd::mysql':
    username => 'nova',
    password => $nova['db_password'],
  }

  class { 'lma_collector::collectd::dbi':
    interval => 15
  }

  lma_collector::collectd::dbi_services { 'nova':
    username        => 'nova',
    dbname          => 'nova',
    password        => $nova['db_password'],
    report_interval => 60,
    factor          => 2,
    require  => Class['lma_collector::collectd::dbi'],
  }

  lma_collector::collectd::dbi_services { 'cinder':
    username => 'cinder',
    dbname   => 'cinder',
    password => $cinder['db_password'],
    require  => Class['lma_collector::collectd::dbi'],
  }

  lma_collector::collectd::dbi_services { 'neutron':
    username        => 'neutron',
    dbname          => 'neutron',
    password        => $neutron['database']['passwd'],
    report_interval => 30,
    factor          => 2,
    require  => Class['lma_collector::collectd::dbi'],
  }

  class { 'lma_collector::logs::metrics': }

  if $enable_notifications {
    class { 'lma_collector::notifications::metrics': }
  }

  # Enable Apache status module
  class { 'lma_collector::mod_status': }

  # Enable service heartbeat metrics
  class { 'lma_collector::metrics::service_heartbeat':
    services => ['mysql', 'rabbitmq', 'haproxy', 'memcached', 'apache']
  }
}
