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
class lma_collector::logs::aggregated_http_metrics (
  $interval = 10,
  $hostname = $::hostname,
  $bulk_size = $lma_collector::params::http_aggregated_metrics_bulk_size,
  $max_timer_inject = $lma_collector::params::hekad_max_timer_inject,
  $percentile = 90,
  $grace_time = 5,
) inherits lma_collector::params {

  include lma_collector::service::log

  $lua_modules_dir = $lma_collector::params::lua_modules_dir

  heka::filter::sandbox { 'aggregated_http_metrics':
    config_dir       => $lma_collector::params::log_config_dir,
    filename         => "${lma_collector::params::plugins_dir}/filters/http_metrics_aggregator.lua",
    message_matcher  => 'Type == \'log\' && Fields[http_response_time] != NIL',
    ticker_interval  => $interval,
    config           => {
      hostname         => $hostname,
      interval         => $interval,
      max_timer_inject => $max_timer_inject,
      bulk_size        => $bulk_size,
      percentile       => $percentile,
      grace_time       => $grace_time,
      source           => 'log_collector',
    },
    module_directory => $lua_modules_dir,
    notify           => Class['lma_collector::service::log'],
  }
}
