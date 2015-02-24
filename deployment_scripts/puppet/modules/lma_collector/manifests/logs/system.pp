class lma_collector::logs::system {
  include lma_collector::params

  heka::decoder::sandbox { 'system':
    config_dir => $lma_collector::params::config_dir,
    filename   => "${lma_collector::plugins_dir}/decoders/generic_syslog.lua" ,
    config     => {
      syslog_pattern => $lma_collector::params::syslog_pattern
    },
    notify     => Service[$lma_collector::params::service_name],
  }

  heka::input::logstreamer { 'system':
    config_dir     => $lma_collector::params::config_dir,
    decoder        => 'system',
    file_match     => '(?P<Service>daemon|cron|kern|auth)\.log$',
    differentiator => "[ 'system.', 'Service' ]",
    require        => Heka::Decoder::Sandbox['system'],
    notify         => Service[$lma_collector::params::service_name],
  }
}
