class lma_collector::pacemaker_logs {
  include lma_collector::params

  heka::decoder::sandbox { 'pacemaker':
    config_dir => $lma_collector::params::config_dir,
    filename   => "${lma_collector::plugins_dir}/decoders/generic_syslog.lua" ,
    config => {
      syslog_pattern => $lma_collector::params::syslog_pattern
    },
    notify     => Service[$lma_collector::params::service_name],
  }

  # Use the <PRI> token as the delimiter because Pacemaker may log messages
  # with newlines and the configuration of the Syslog daemon doesn't escape
  # them.
  heka::splitter::regex { 'pacemaker':
    config_dir    => $lma_collector::params::config_dir,
    delimiter     => '\n(<[0-9]+>)',
    delimiter_eol => false,
    notify        => Service[$lma_collector::params::service_name],
  }

  heka::input::logstreamer { 'pacemaker':
    config_dir     => $lma_collector::params::config_dir,
    decoder        => 'pacemaker',
    splitter       => 'pacemaker',
    file_match     => 'pacemaker\.log$',
    differentiator => "[ 'pacemaker' ]",
    require        => [Heka::Decoder::Sandbox['pacemaker'], Heka::Splitter::Regex['pacemaker']],
    notify         => Service[$lma_collector::params::service_name],
  }
}
