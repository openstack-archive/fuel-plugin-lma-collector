class lma_collector::logs::rabbitmq {
  include lma_collector::params
  include lma_collector::service

  heka::decoder::sandbox { 'rabbitmq':
    config_dir => $lma_collector::params::config_dir,
    filename   => "${lma_collector::params::plugins_dir}/decoders/rabbitmq.lua" ,
    notify     => Class['lma_collector::service'],
  }

  heka::splitter::regex { 'rabbitmq':
    config_dir    => $lma_collector::params::config_dir,
    delimiter     => '\n(=[^=]+====)',
    delimiter_eol => false,
    notify        => Class['lma_collector::service'],
  }

  heka::input::logstreamer { 'rabbitmq':
    config_dir     => $lma_collector::params::config_dir,
    decoder        => 'rabbitmq',
    splitter       => 'rabbitmq',
    log_directory  => "/var/log/rabbitmq",
    file_match     => 'rabbit@(?P<Node>.+)\.log$',
    differentiator => '["rabbitmq.", "Node"]',
    require        => [Heka::Decoder::Sandbox['rabbitmq'], Heka::Splitter::Regex['rabbitmq']],
    notify         => Class['lma_collector::service'],
  }
}
