class lma_collector::metrics::service_status (
  $metrics_regexp = [],
  $timeout  = $lma_collector::params::service_status_timeout,
){
  include heka::params

  validate_array($metrics_regexp)

  if (size(metrics_regexp) > 0){
    heka::filter::sandbox { 'service_status':
      config_dir      => $lma_collector::params::config_dir,
      filename        => "${lma_collector::params::plugins_dir}/filters/service_status.lua",
      message_matcher => inline_template('<%= @metrics_regexp.collect{|x| "Fields[name] =~ /%s/" % x}.join(" || ") %>'),
      ticker_interval => 10,
      config          => {
        timeout => $timeout,
      },
      notify          => Class['lma_collector::service'],
    }
  }
}
