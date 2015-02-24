class lma_collector::elasticsearch (
  $server = $lma_collector::params::elasticsearch_server,
  $port = $lma_collector::params::elasticsearch_port,
) {
  include lma_collector::params

  validate_string($server)

  heka::encoder::es_json { 'elasticsearch':
    config_dir              => $lma_collector::params::config_dir,
    index                   => "%{Type}-%{2006.01.02}",
    es_index_from_timestamp => true,
    notify                  => Service[$lma_collector::params::service_name],
  }

  heka::output::elasticsearch { 'elasticsearch':
    config_dir      => $lma_collector::params::config_dir,
    server          => $server,
    port            => $port,
    message_matcher => "Type == 'log'",
    require         => Heka::Encoder::Es_json['elasticsearch'],
    notify          => Service[$lma_collector::params::service_name],
  }
}
