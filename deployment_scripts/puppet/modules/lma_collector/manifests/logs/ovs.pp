class lma_collector::logs::ovs {
  include lma_collector::params
  include lma_collector::service

  heka::decoder::sandbox { 'ovs':
    config_dir => $lma_collector::params::config_dir,
    filename   => "${lma_collector::params::plugins_dir}/decoders/ovs_log.lua",
    notify     => Class['lma_collector::service'],
  }

  heka::input::logstreamer { 'ovs':
    config_dir     => $lma_collector::params::config_dir,
    decoder        => 'ovs',
    log_directory  => '/var/log/openvswitch',
    file_match     => '(?P<Service>ovs\-vswitchd|ovsdb\-server)\.log$',
    differentiator => "[ 'Service' ]",
    require        => Heka::Decoder::Sandbox['ovs'],
    notify         => Class['lma_collector::service'],
  }
}
