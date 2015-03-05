class lma_collector::elasticsearch (
  $server = $lma_collector::params::elasticsearch_server,
  $port = $lma_collector::params::elasticsearch_port,
) inherits lma_collector::params {
  include lma_collector::service

  validate_string($server)

  heka::encoder::es_json { 'elasticsearch':
    config_dir              => $lma_collector::params::config_dir,
    index                   => "%{Type}-%{2006.01.02}",
    es_index_from_timestamp => true,
    notify                  => Class['lma_collector::service'],
  }

  heka::output::elasticsearch { 'elasticsearch':
    config_dir      => $lma_collector::params::config_dir,
    server          => $server,
    port            => $port,
    message_matcher => "Type == 'log' || Type  == 'notification'",
    require         => Heka::Encoder::Es_json['elasticsearch'],
    notify          => Class['lma_collector::service'],
  }
}
