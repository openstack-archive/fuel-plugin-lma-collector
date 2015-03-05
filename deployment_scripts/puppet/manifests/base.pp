# TODO(spasquier): replace by Hiera when testing with 6.1
$fuel_settings = parseyaml(file('/etc/astute.yaml'))

# TODO(spasquier): fail if Neutron isn't used

$roles = node_roles($fuel_settings['nodes'], $fuel_settings['uid'])

$tags = {
  deployment_id => $fuel_settings['deployment_id'],
  deployment_mode => $fuel_settings['deployment_mode'],
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

class { 'lma_collector':
  tags => merge($tags, $additional_tags)
}

class { 'lma_collector::logs::system':
  require => Class['lma_collector'],
}

class { 'lma_collector::logs::monitor':
  require => Class['lma_collector'],
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
  server => $es_server,
  require => Class['lma_collector'],
}
