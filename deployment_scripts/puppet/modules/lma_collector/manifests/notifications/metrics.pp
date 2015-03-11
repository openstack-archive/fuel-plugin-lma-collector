class lma_collector::notifications::metrics {
  include lma_collector::params
  include lma_collector::service

  # Filter to compute the instance creation time metric
  heka::filter::sandbox { 'instance_creation_time':
    config_dir      => $lma_collector::params::config_dir,
    filename        => "${lma_collector::params::plugins_dir}/filters/instance_creation_time.lua",
    message_matcher => "Type == 'notification' && Fields[event_type] == 'compute.instance.create.end'",
    notify          => Class['lma_collector::service'],
  }

  # Filter to compute the instance state change metric
  heka::filter::sandbox { 'instance_state':
    config_dir      => $lma_collector::params::config_dir,
    filename        => "${lma_collector::params::plugins_dir}/filters/instance_state.lua",
    message_matcher => "Type == 'notification' && Fields[event_type] == 'compute.instance.update' && Fields[state] != NIL",
    notify          => Class['lma_collector::service'],
  }
}
