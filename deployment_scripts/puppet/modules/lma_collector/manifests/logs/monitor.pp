class lma_collector::logs::monitor {
  include lma_collector::params
  include lma_collector::service

  heka::filter::sandbox { 'log_monitor':
    config_dir      => $lma_collector::params::config_dir,
    filename        => "${lma_collector::params::plugins_dir}/filters/log_monitor.lua" ,
    message_matcher => 'Type == \'log\'',
    ticker_interval => 60,
    notify          => Class['lma_collector::service'],
  }
}
