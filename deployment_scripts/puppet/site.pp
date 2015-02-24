$fuel_settings = parseyaml(file('/etc/astute.yaml'))

$deployment_mode = $fuel_settings['deployment_mode']
if $deployment_mode == 'multinode' {
  $controller_role = 'controller'
}
elsif $deployment_mode =~ /^ha/ {
  $controller_role = 'primary-controller'
}
else {
  fail ("'${deployment_mode} is not a supported deployment mode")
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

class lma_common {
  class { 'lma_collector':
    tags => {
      fuel_environment => $fuel_settings['lma_collector']['fuel_environment'],
      openstack_region => 'RegionOne',
      openstack_release => $fuel_settings['openstack_version'],
      openstack_roles => join($roles, ","),
      deployment_mode => $deployment_mode,
    }
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

if $fuel_settings['lma_collector']['elasticsearch_server'] != '' {
  class { 'lma_common': }

  if ($is_primary_controller or $is_controller) {
    class { 'lma_controller': }
  }

  class { 'lma_collector::elasticsearch':
    server => $fuel_settings['lma_collector']['elasticsearch_server']
  }
}
