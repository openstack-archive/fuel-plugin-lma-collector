#    Copyright 2016 Mirantis, Inc.
#
#    Licensed under the Apache License, Version 2.0 (the "License"); you may
#    not use this file except in compliance with the License. You may obtain
#    a copy of the License at
#
#         http://www.apache.org/licenses/LICENSE-2.0
#
#    Unless required by applicable law or agreed to in writing, software
#    distributed under the License is distributed on an "AS IS" BASIS, WITHOUT
#    WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. See the
#    License for the specific language governing permissions and limitations
#    under the License.
#
# == Define: lma_collector::heka
#
# The lma_collector::heka resource installs and configures heka service
#
# === Parameters
#
# === Examples
#
# === Authors
#
# Simon Pasquier <spasquier@mirantis.com>
# Swann Croiset <scroiset@mirantis.com>
#
# === Copyright
#
# Copyright 2016 Mirantis Inc., unless otherwise noted.
#
define lma_collector::heka (
  $user = 'heka',
  $groups = [],
  $heka_monitoring = true,
  $poolsize = 100,
  $install_init_script = true,
  $version = 'latest',
) {

  include lma_collector::params

  validate_array($groups)
  validate_bool($heka_monitoring)
  validate_integer($poolsize)

  if ! member(['log_collector', 'metric_collector'], $title){
    fail('lma_collector::heka title must be either "log_collector" or "metric_collector"')
  }

  $lua_modules_dir = $lma_collector::params::lua_modules_dir

  $additional_groups = $user ? {
    'root'  => [],
    default => union($lma_collector::params::groups, $groups),
  }

  if $title == 'metric_collector' {

    $config_dir = $lma_collector::params::metric_config_dir
    $service_class = 'lma_collector::service::metric'
    $dashboard_port = $lma_collector::params::metric_dashboard_port

    heka::decoder::sandbox { 'metric':
      config_dir       => $config_dir,
      filename         => "${lma_collector::params::plugins_dir}/decoders/metric.lua",
      module_directory => $lua_modules_dir,
      config           => {
        'deserialize_bulk_metric_for_loggers' => 'aggregated_http_metrics_filter hdd_errors_counter_filter logs_counter_filter'},
      notify           => Class[$service_class],
    }

    heka::input::tcp { 'metric':
      config_dir => $config_dir,
      address    => $lma_collector::params::metric_input_address,
      port       => $lma_collector::params::metric_input_port,
      decoder    => 'metric',
      require    => [::Heka[$title], Heka::Decoder::Sandbox['metric']],
      notify     => Class[$service_class],
    }

  } elsif $title == 'log_collector' {

    $config_dir = $lma_collector::params::log_config_dir
    $service_class = 'lma_collector::service::log'
    $dashboard_port = $lma_collector::params::log_dashboard_port

    heka::output::tcp { 'metric':
      config_dir        => $config_dir,
      address           => $lma_collector::params::metric_input_address,
      port              => $lma_collector::params::metric_input_port,
      message_matcher   => '(Type == \'metric\' || Type == \'heka.sandbox.metric\' || Type == \'heka.sandbox.bulk_metric\')',
      max_buffer_size   => $lma_collector::params::buffering_max_buffer_log_metric_size,
      max_file_size     => $lma_collector::params::buffering_max_file_log_metric_size,
      queue_full_action => $lma_collector::params::queue_full_action_log_metric,
      require           => ::Heka[$title],
      notify            => Class[$service_class],
    }
  }

  ::heka { $title:
    config_dir          => $config_dir,
    user                => $user,
    additional_groups   => $additional_groups,
    hostname            => $::hostname,
    max_message_size    => $lma_collector::params::hekad_max_message_size,
    max_process_inject  => $lma_collector::params::hekad_max_process_inject,
    max_timer_inject    => $lma_collector::params::hekad_max_timer_inject,
    poolsize            => $poolsize,
    install_init_script => $install_init_script,
    version             => $version,
  }

  # Heka self-monitoring
  if $heka_monitoring {
    $heka_monitoring_ensure = present
  } else {
    $heka_monitoring_ensure = absent
  }

  heka::filter::sandbox { "heka_monitoring_${title}":
    ensure           => $heka_monitoring_ensure,
    config_dir       => $config_dir,
    filename         => "${lma_collector::params::plugins_dir}/filters/heka_monitoring.lua",
    message_matcher  => "Type == 'heka.all-report'",
    require          => ::Heka[$title],
    module_directory => $lua_modules_dir,
    notify           => Class[$service_class],
  }

  # Dashboard is required to enable monitoring messages
  heka::output::dashboard { "dashboard_${title}":
    ensure            => $heka_monitoring_ensure,
    config_dir        => $config_dir,
    dashboard_address => $lma_collector::params::dashboard_address,
    dashboard_port    => $dashboard_port,
    require           => ::Heka[$title],
    notify            => Class[$service_class],
  }
}
