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
lma_collector::logs::openstack { ['cinder', 'glance', 'heat', 'horizon',
    'keystone', 'neutron', 'nova']:
  require => Class['lma_collector'],
}
class {'lma_collector::logs::keystone_wsgi':
  require => Class['lma_collector'],
}

class { 'lma_collector::elasticsearch':
  server  => 'elasticsearch.example.com',
  require => Class['lma_collector'],
}

# Configure metrics collection and output
class { 'lma_collector::collectd::base':
  purge => true,
}

lma_collector::collectd::openstack { ['cinder', 'glance', 'keystone',
    'neutron', 'nova']:
  user         => 'lma',
  password     => 'supersecret',
  tenant       => 'admin',
  keystone_url => 'http://keystone.example.com:5000/v2.0',
  require      => Class['lma_collector::collectd::base'],
}

class { 'lma_collector::collectd::openstack_checks':
  user         => 'lma',
  password     => 'supersecret',
  tenant       => 'admin',
  keystone_url => 'http://keystone.example.com:5000/v2.0',
  require      => Class['lma_collector::collectd::base'],
}

class { 'lma_collector::collectd::hypervisor':
  user         => 'lma',
  password     => 'supersecret',
  tenant       => 'admin',
  keystone_url => 'http://keystone.example.com:5000/v2.0',
  require      => Class['lma_collector::collectd::base'],
}

class { 'lma_collector::logs::counter':
  hostname => $::hostname,
  require  => Class['lma_collector'],
}
class { 'lma_collector::logs::http_metrics': }

class { 'lma_collector::influxdb':
  server     => 'influxdb.example.com',
  database   => 'lma',
  user       => 'lma',
  password   => 'secret',
  tag_fields => ['environment', 'region'],
  require    => Class['lma_collector'],
}
