# TODO(spasquier): replace by Hiera when testing with 6.1
$fuel_settings = parseyaml(file('/etc/astute.yaml'))

# TODO(spasquier): fail if Neutron isn't used

$roles = node_roles($fuel_settings['nodes'], $fuel_settings['uid'])

$tags = {
  deployment_id => $fuel_settings['deployment_id'],
  deployment_mode => $fuel_settings['deployment_mode'],
  openstack_region => 'RegionOne',
  openstack_release => $fuel_settings['openstack_version'],
  openstack_roles => join($roles, ','),
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

if (str2bool($::ovs_log_directory)){
  # install logstreamer for open vSwitch if log directory exists
  class { 'lma_collector::logs::ovs':
    require => Class['lma_collector'],
  }
}

class { 'lma_collector::logs::monitor':
  require => Class['lma_collector'],
}

$influxdb_mode = $fuel_settings['lma_collector']['influxdb_mode']
case $influxdb_mode {
  'remote','local': {
    if $influxdb_mode == 'remote' {
      $influxdb_server = $fuel_settings['lma_collector']['influxdb_address']
    }
    else {
      $influxdb_node_name = $fuel_settings['lma_collector']['influxdb_node_name']
      $influxdb_nodes = filter_nodes($fuel_settings['nodes'], 'user_node_name', $influxdb_node_name)
      if size($influxdb_nodes) < 1 {
        fail("Could not find node '${influxdb_node_name}' in the environment")
      }
      $influxdb_server = $influxdb_nodes[0]['internal_address']
    }

    class { 'lma_collector::collectd::base':
    }

    class { 'lma_collector::influxdb':
      server   => $influxdb_server,
      database => $fuel_settings['lma_collector']['influxdb_database'],
      user     => $fuel_settings['lma_collector']['influxdb_user'],
      password => $fuel_settings['lma_collector']['influxdb_password'],
    }
  }
  'disabled': {
    # Nothing to do
  }
  default: {
    fail("'${influxdb_mode}' mode not supported for InfluxDB")
  }
}

$elasticsearch_mode = $fuel_settings['lma_collector']['elasticsearch_mode']
case $elasticsearch_mode {
  'remote': {
    $es_server = $fuel_settings['lma_collector']['elasticsearch_address']
  }
  'local': {
    $es_node_name = $fuel_settings['lma_collector']['elasticsearch_node_name']
    $es_nodes = filter_nodes($fuel_settings['nodes'], 'user_node_name', $es_node_name)
    if size($es_nodes) < 1 {
      fail("Could not find node '${es_node_name}' in the environment")
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
