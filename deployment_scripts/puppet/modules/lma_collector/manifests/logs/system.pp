class lma_collector::logs::system {
  include lma_collector::params
  include lma_collector::service

  heka::decoder::sandbox { 'system':
    config_dir => $lma_collector::params::config_dir,
    filename   => "${lma_collector::params::plugins_dir}/decoders/generic_syslog.lua" ,
    config     => {
      syslog_pattern => $lma_collector::params::syslog_pattern
    },
    notify     => Class['lma_collector::service'],
  }

  heka::input::logstreamer { 'system':
    config_dir     => $lma_collector::params::config_dir,
    decoder        => 'system',
    file_match     => '(?P<Service>daemon\.log|cron\.log|kern\.log|auth\.log|syslog|messages|debug)',
    differentiator => '[ \'system.\', \'Service\' ]',
    require        => Heka::Decoder::Sandbox['system'],
    notify         => Class['lma_collector::service'],
  }
}
