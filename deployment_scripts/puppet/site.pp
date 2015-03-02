# TODO(spasquier): replace by Hiera when testing with 6.1
$fuel_settings = parseyaml(file('/etc/astute.yaml'))

# TODO(spasquier): fail if Neutron isn't used

include lma_collector::params

$deployment_mode = $fuel_settings['deployment_mode']

$roles = node_roles($fuel_settings['nodes'], $fuel_settings['uid'])
$roles_map = {}
$roles_map['primary-controller'] = member($roles, 'primary-controller')
$roles_map['controller'] = member($roles, 'controller')
$roles_map['compute'] = member($roles, 'compute')
$roles_map['cinder'] = member($roles, 'cinder')
$roles_map['ceph-osd'] = member($roles, 'ceph-osd')

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

$enable_notifications = $fuel_settings['lma_collector']['enable_notifications']
if $fuel_settings['ceilometer']['enabled'] {
  $notification_topics = [$lma_collector::params::openstack_topic, $lma_collector::params::lma_topic]
}
else {
  $notification_topics = [$lma_collector::params::lma_topic]
}

# Resources shared by all roles
class { 'lma_collector':
  tags => merge($tags, $additional_tags)
}

class { 'lma_collector::logs::system': }

class { 'lma_collector::logs::openstack': }

class { 'lma_collector::logs::monitor': }

# Controller
if ($roles_map['primary-controller'] or $roles_map['controller']) {
  # Logs
  class { 'lma_collector::logs::mysql': }

  class { 'lma_collector::logs::rabbitmq': }

  if $deployment_mode =~ /^ha/ {
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
}

# Compute
if $roles_map['compute'] and $enable_notifications {
  class { 'lma_collector::notifications::compute':
    topics  => $notification_topics,
  }
}

# Cinder
if $roles_map['cinder'] and $enable_notifications {
  class { 'lma_collector::notifications::cinder':
    topics  => $notification_topics,
  }
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
