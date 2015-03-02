$fuel_settings = parseyaml(file('/etc/astute.yaml'))

$deployment_mode = $fuel_settings['deployment_mode']
if $deployment_mode == 'multinode' {
  $controller_role = 'controller'
}
elsif $deployment_mode =~ /^ha/ {
  $controller_role = 'primary-controller'
}
else {
  fail("'${deployment_mode} is not a supported deployment mode")
}

# TODO: verify that we're running Neutron

$roles = node_roles($fuel_settings['nodes'], $fuel_settings['uid'])
$roles_map = {}
$roles_map['primary-controller'] = member($roles, 'primary-controller')
$roles_map['controller'] = member($roles, 'controller')
$roles_map['compute'] = member($roles, 'compute')
$roles_map['cinder'] = member($roles, 'cinder')
$roles_map['ceph-osd'] = member($roles, 'ceph-osd')
$is_primary_controller = member($roles, $controller_role)
$is_controller = $roles_map['controller']

$tags = {
  deployment_id => $fuel_settings['deployment_id'],
  deployment_mode => $deployment_mode,
  openstack_region => 'RegionOne',
  openstack_release => $fuel_settings['openstack_version'],
  openstack_roles => join($roles, ","),
}
if $fuel_settings['lma_collector']['environment_label'] != '' {
  $additional_tags = {
    environment_label => $fuel_settings['lma_collector']['environment_label'],
  }
}
else {
  $additional_tags = {}
}

class lma_common {
  class { 'lma_collector':
    tags => merge($tags, $additional_tags)
  }

  class { 'lma_collector::logs::system': }

  class { 'lma_collector::logs::openstack': }

  class { 'lma_collector::logs::monitor': }
}

class lma_controller (
  $rabbitmq_host,
  $rabbitmq_user,
  $rabbitmq_password,
) {
  class { 'lma_collector::logs::mysql': }

  class { 'lma_collector::logs::rabbitmq': }

  class { 'lma_collector::logs::pacemaker': }

  class { 'lma_collector::notifications':
    host => $rabbitmq_host,
    user => $rabbitmq_user,
    password => $rabbitmq_password,
    # We need to pick one exchange and we settled on 'nova'. The default
    # exchange ("") doesn't work because Heka would fail to create the queue in
    # case it doesn't exist yet.
    exchange => 'nova'
  }
}

class { 'lma_common': }

if ($is_primary_controller or $is_controller) {
  if $fuel_settings['rabbit']['user'] {
    $rabbitmq_user = $fuel_settings['rabbit']['user']
  }
  else {
    $rabbitmq_user = 'nova'
  }

  class { 'lma_controller':
    rabbitmq_host => $fuel_settings['management_vip'],
    rabbitmq_user => $rabbitmq_user,
    rabbitmq_password => $fuel_settings['rabbit']['password'],
  }
}

if $fuel_settings['lma_collector']['enable_notifications'] {
  include lma_collector::params

  $notification_driver = 'messaging'

  if $fuel_settings['ceilometer']['enabled'] {
    $notification_topics = 'notifications,' + $lma_collector::params::notification_topic
  }
  else {
    $notification_topics = $lma_collector::params::notification_topic
  }

  if member($roles, 'compute') {
    include nova::params

    nova_config {
      'DEFAULT/notification_topics': value => $notification_topics,
      notify => Service[$::nova::params::compute_service_name],
    }

    nova_config {
      'DEFAULT/notification_driver': value => $notification_driver,
      notify => Service[$::nova::params::compute_service_name],
    }

    service { $::nova::params::compute_service_name:
    }
  }
  # TODO(spasquier): The same for all services + all roles
}

$elasticsearch_mode = $fuel_settings['lma_collector']['elasticsearch_mode']
case $elasticsearch_mode {
  'remote': {
    $es_server = $fuel_settings['lma_collector']['elasticsearch_address']
  }
  'local': {
    $node_name = $fuel_settings['lma_collector']['elasticsearch_node_name']
    $es_nodes = filter_nodes($fuel_settings['nodes'], 'user_node_name', $node_name)
    if size($es_nodes) < 1 {
      fail("Could not find node '${node_name}' in the environment")
    }
    $es_server = $es_nodes[0]['internal_address']
  }
  default: {
    fail("'${elasticsearch_mode}' mode not supported for ElasticSearch")
  }
}

class { 'lma_collector::elasticsearch':
  server => $es_server
}
