class lma_collector::metrics::service_heartbeat (
  $services,
  $timeout  = $lma_collector::params::heartbeat_timeout,
) inherits lma_collector::params {
  include lma_collector::service

  validate_array($services)

  if (size($services) > 0) {
    $regexp = join(sort($services), '|')

    heka::filter::sandbox { 'service_heartbeat':
      config_dir      => $lma_collector::params::config_dir,
      filename        => "${lma_collector::params::plugins_dir}/filters/service_heartbeat.lua",
      message_matcher => join(['Fields[name] =~ /^', join(sort($services), '|'), '/'], ''),
      ticker_interval => 10,
      config          => {
        timeout => $timeout,
      },
      notify          => Class['lma_collector::service'],
    }
  }
}
