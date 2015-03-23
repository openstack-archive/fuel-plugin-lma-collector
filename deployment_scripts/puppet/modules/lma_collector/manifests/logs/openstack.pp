class lma_collector::logs::openstack {
  include lma_collector::params
  include lma_collector::service

  heka::decoder::sandbox { 'openstack':
    config_dir => $lma_collector::params::config_dir,
    filename   => "${lma_collector::params::plugins_dir}/decoders/openstack_log.lua" ,
    config     => {
      syslog_pattern => $lma_collector::params::syslog_pattern
    },
    notify     => Class['lma_collector::service'],
  }

  # Use the <PRI> token as the delimiter because OpenStack services may log
  # messages with newlines and the configuration of the Syslog daemon doesn't
  # escape them.
  heka::splitter::regex { 'openstack':
    config_dir    => $lma_collector::params::config_dir,
    delimiter     => '(<[0-9]+>)',
    delimiter_eol => false,
    notify        => Class['lma_collector::service'],
  }

  heka::input::logstreamer { 'openstack':
    config_dir     => $lma_collector::params::config_dir,
    decoder        => 'openstack',
    splitter       => 'openstack',
    file_match     => '(?P<Service>nova|cinder|keystone|glance|heat|neutron|murano)-all\.log$',
    differentiator => '[ \'openstack.\', \'Service\' ]',
    require        => [Heka::Decoder::Sandbox['openstack'], Heka::Splitter::Regex['openstack']],
    notify         => Class['lma_collector::service'],
  }

  heka::input::logstreamer { 'openstack_dashboard':
    config_dir     => $lma_collector::params::config_dir,
    decoder        => 'openstack',
    file_match     => 'dashboard\.log$',
    differentiator => '[ \'openstack.horizon\' ]',
    require        => Heka::Decoder::Sandbox['openstack'],
    notify         => Class['lma_collector::service'],
  }
}
