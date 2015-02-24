class lma_collector::rabbitmq_logs {
  include lma_collector::params

  heka::decoder::sandbox { 'rabbitmq':
    config_dir => $lma_collector::params::config_dir,
    filename   => "${lma_collector::plugins_dir}/decoders/rabbitmq.lua" ,
    notify     => Service[$lma_collector::params::service_name],
  }

  heka::splitter::regex { 'rabbitmq':
    config_dir    => $lma_collector::params::config_dir,
    delimiter     => '\n(=[^=]+====)',
    delimiter_eol => false,
    notify        => Service[$lma_collector::params::service_name],
  }

  heka::input::logstreamer { 'rabbitmq':
    config_dir     => $lma_collector::params::config_dir,
    decoder        => 'rabbitmq',
    splitter       => 'rabbitmq',
    log_directory  => "/var/log/rabbitmq",
    file_match     => 'rabbit@(?P<Node>.+)\.log$',
    differentiator => '["rabbitmq.", "Node"]',
    require        => [Heka::Decoder::Sandbox['rabbitmq'], Heka::Splitter::Regex['rabbitmq']],
    notify         => Service[$lma_collector::params::service_name],
  }
}
