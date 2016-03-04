# Install and configure the bare LMA collector service
class {'lma_collector':
  tags => {
    environment => 'prod',
    region      => 'us_west'
  },
  user => 'heka',
}

# Configure logs collection and output
class { 'lma_collector::logs::system':
  require => Class['lma_collector'],
}
class { 'lma_collector::logs::ovs':
  require => Class['lma_collector'],
}
lma_collector::logs::openstack { 'nova':
  require => Class['lma_collector'],
}
lma_collector::logs::openstack { 'neutron':
  require => Class['lma_collector'],
}
class { 'lma_collector::logs::libvirt':
  require => Class['lma_collector'],
}

class { 'lma_collector::elasticsearch':
  server  => 'elasticsearch.example.com',
  require => Class['lma_collector'],
}

# Configure metrics collection and output
class { 'lma_collector::collectd::base':
  purge => true,
} ->
class { 'lma_collector::collectd::libvirt': }

class { 'lma_collector::logs::counter':
  hostname => $::hostname,
  require  => Class['lma_collector'],
}

class { 'lma_collector::influxdb':
  server     => 'influxdb.example.com',
  database   => 'lma',
  user       => 'lma',
  password   => 'secret',
  tag_fields => ['environment', 'region'],
  require    => Class['lma_collector'],
}
