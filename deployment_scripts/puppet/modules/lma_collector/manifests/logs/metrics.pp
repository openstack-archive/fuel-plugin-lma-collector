class lma_collector::logs::metrics {
  include lma_collector::params
  include lma_collector::service

  heka::filter::sandbox { 'http_metrics':
    config_dir      => $lma_collector::params::config_dir,
    filename        => "${lma_collector::params::plugins_dir}/filters/http_metrics.lua",
    message_matcher => "Type == 'log' && Logger =~ /^openstack/ && Payload =~ /HTTP/",
    notify          => Class['lma_collector::service'],
  }
}
