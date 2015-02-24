class lma_collector::logs::mysql {
  include lma_collector::params

  heka::decoder::sandbox { 'mysql':
    config_dir => $lma_collector::params::config_dir,
    filename   => "${lma_collector::plugins_dir}/decoders/mysql_log.lua" ,
    config     => {
      syslog_pattern => $lma_collector::params::syslog_pattern
    },
    notify     => Service[$lma_collector::params::service_name],
  }

  heka::input::logstreamer { 'mysql':
    config_dir     => $lma_collector::params::config_dir,
    decoder        => 'mysql',
    file_match     => 'mysqld\.log$',
    differentiator => "['mysql']",
    require        => Heka::Decoder::Sandbox['mysql'],
    notify         => Service[$lma_collector::params::service_name],
  }
}
