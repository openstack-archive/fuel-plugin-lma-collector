class lma_collector::logs::openstack {
  include lma_collector::params

  heka::decoder::sandbox { 'openstack':
    config_dir => $lma_collector::params::config_dir,
    filename   => "${lma_collector::plugins_dir}/decoders/openstack_log.lua" ,
    config     => {
      syslog_pattern => $lma_collector::params::syslog_pattern
    },
    notify     => Service[$lma_collector::params::service_name],
  }

  # Use the <PRI> token as the delimiter because OpenStack services may log
  # messages with newlines and the configuration of the Syslog daemon doesn't
  # escape them.
  heka::splitter::regex { 'openstack':
    config_dir    => $lma_collector::params::config_dir,
    delimiter     => '(<[0-9]+>)',
    delimiter_eol => false,
    notify        => Service[$lma_collector::params::service_name],
  }

  heka::input::logstreamer { 'openstack':
    config_dir     => $lma_collector::params::config_dir,
    decoder        => 'openstack',
    splitter       => 'openstack',
    file_match     => '(?P<Service>nova|cinder|keystone|glance|heat|neutron)-all\.log$',
    differentiator => "[ 'openstack.', 'Service' ]",
    require        => [Heka::Decoder::Sandbox['openstack'], Heka::Splitter::Regex['openstack']],
    notify         => Service[$lma_collector::params::service_name],
  }

  heka::input::logstreamer { 'openstack_dashboard':
    config_dir     => $lma_collector::params::config_dir,
    decoder        => 'openstack',
    file_match     => 'dashboard\.log$',
    differentiator => "[ 'openstack.horizon' ]",
    require        => Heka::Decoder::Sandbox['openstack'],
    notify         => Service[$lma_collector::params::service_name],
  }
}
