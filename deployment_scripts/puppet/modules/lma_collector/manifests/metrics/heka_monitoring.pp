#    Copyright 2015 Mirantis, Inc.
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
class lma_collector::metrics::heka_monitoring (
  $dashboard_address     = $lma_collector::params::dashboard_address,
  $log_dashboard_port    = $lma_collector::params::log_dashboard_port,
  $metric_dashboard_port = $lma_collector::params::metric_dashboard_port,
) inherits lma_collector::params {

  include lma_collector::service::metric
  include lma_collector::service::log

  $metric_config_dir = $lma_collector::params::metric_config_dir
  $log_config_dir = $lma_collector::params::log_config_dir

  heka::filter::sandbox { 'heka_monitoring_metric':
    config_dir      => $metric_config_dir,
    filename        => "${lma_collector::params::plugins_dir}/filters/heka_monitoring.lua",
    message_matcher => "Type == 'heka.all-report'",
    notify          => Class['lma_collector::service::metric'],
  }
  heka::filter::sandbox { 'heka_monitoring_log':
    config_dir      => $log_config_dir,
    filename        => "${lma_collector::params::plugins_dir}/filters/heka_monitoring.lua",
    message_matcher => "Type == 'heka.all-report'",
    notify          => Class['lma_collector::service::log'],
  }

  # Dashboard is required to enable monitoring messages
  heka::output::dashboard { 'dashboard_metric':
    config_dir        => $metric_config_dir,
    dashboard_address => $dashboard_address,
    dashboard_port    => $metric_dashboard_port,
    notify            => Class['lma_collector::service::metric'],
  }
  heka::output::dashboard { 'dashboard_log':
    config_dir        => $log_config_dir,
    dashboard_address => $dashboard_address,
    dashboard_port    => $log_dashboard_port,
    notify            => Class['lma_collector::service::log'],
  }
}
