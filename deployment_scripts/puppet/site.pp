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
$is_primary_controller = member($roles, $controller_role)
$is_controller = member($roles, 'controller')

if $fuel_settings['rabbit']['user'] {
  $rabbitmq_user = $fuel_settings['rabbit']['user']
}
else {
  $rabbitmq_user = 'nova'
}

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

class lma_controller {
  class { 'lma_collector::logs::mysql': }

  class { 'lma_collector::logs::rabbitmq': }

  class { 'lma_collector::logs::pacemaker': }
}

class { 'lma_common': }

if ($is_primary_controller or $is_controller) {
  class { 'lma_controller': }
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
