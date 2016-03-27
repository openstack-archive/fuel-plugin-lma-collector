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
define lma_collector::metrics::heka_monitoring (
  $dashboard_address = undef,
  $dashboard_port    = undef,
) {

  include lma_collector::params

  if $title != 'metric' and $title != 'log' {
    fail('$title must be either \'metric\' or \'log\'')
  }

  if $dashboard_address {
    $_dashboard_address = $dashboard_address
  } else {
    $_dashboard_address = $lma_collector::params::dashboard_address
  }

  if $title == 'metric' {
    include lma_collector::service::metric
    $config_dir = $lma_collector::params::metric_config_dir
    if $dashboard_port {
      $_dashboard_port = $dashboard_port
    } else {
      $_dashboard_port = $lma_collector::params::metric_dashboard_port
    }
  } else {
    include lma_collector::service::log
    $config_dir = $lma_collector::params::log_config_dir
    if $dashboard_port {
      $_dashboard_port = $dashboard_port
    } else {
      $_dashboard_port = $lma_collector::params::log_dashboard_port
    }
  }

  heka::filter::sandbox { "heka_monitoring_${title}":
    config_dir      => $config_dir,
    filename        => "${lma_collector::params::plugins_dir}/filters/heka_monitoring.lua",
    message_matcher => "Type == 'heka.all-report'",
    notify          => Class["lma_collector::service::${title}"],
  }

  # Dashboard is required to enable monitoring messages
  heka::output::dashboard { "dashboard_${title}":
    config_dir        => $config_dir,
    dashboard_address => $_dashboard_address,
    dashboard_port    => $_dashboard_port,
    notify            => Class["lma_collector::service::${title}"],
  }
}
