class lma_collector::log_monitor {
  include lma_collector::params

  heka::filter::sandbox { 'log_monitor':
    config_dir      => $lma_collector::params::config_dir,
    filename        => "${lma_collector::plugins_dir}/filters/log_monitor.lua" ,
    message_matcher => "Type == 'log'",
    ticker_interval => 60,
    notify          => Service[$lma_collector::params::service_name],
  }
}
