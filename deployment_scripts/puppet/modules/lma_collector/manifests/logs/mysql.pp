class lma_collector::logs::mysql {
  include lma_collector::params
  include lma_collector::service

  heka::decoder::sandbox { 'mysql':
    config_dir => $lma_collector::params::config_dir,
    filename   => "${lma_collector::params::plugins_dir}/decoders/mysql_log.lua" ,
    config     => {
      syslog_pattern => $lma_collector::params::syslog_pattern
    },
    notify     => Class['lma_collector::service'],
  }

  heka::input::logstreamer { 'mysql':
    config_dir     => $lma_collector::params::config_dir,
    decoder        => 'mysql',
    file_match     => 'mysqld\.log$',
    differentiator => '[\'mysql\']',
    require        => Heka::Decoder::Sandbox['mysql'],
    notify         => Class['lma_collector::service'],
  }
}
