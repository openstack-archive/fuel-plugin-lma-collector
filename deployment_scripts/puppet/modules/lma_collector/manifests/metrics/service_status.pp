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
class lma_collector::metrics::service_status (
  $metrics_regexp = $lma_collector::params::service_status_metrics_regexp,
  $payload_name = $lma_collector::params::service_status_payload_name,
  $timeout  = $lma_collector::params::service_status_timeout,
){
  include heka::params

  validate_array($metrics_regexp)

  if (size(metrics_regexp) > 0){

    heka::filter::sandbox { 'service_accumulator_states':
      config_dir            => $lma_collector::params::config_dir,
      filename              => "${lma_collector::params::plugins_dir}/filters/service_accumulator_states.lua",
      message_matcher       => inline_template('<%= @metrics_regexp.collect{|x| "Fields[name] =~ /%s/" % x}.join(" || ") %>'),
      ticker_interval       => 10,
      preserve_data         => true,
      config                => {
        inject_payload_name => $payload_name,
      },
      notify                => Class['lma_collector::service'],
    }

    heka::filter::sandbox { 'service_status':
      config_dir      => $lma_collector::params::config_dir,
      filename        => "${lma_collector::params::plugins_dir}/filters/service_status.lua",
      message_matcher => "Fields[payload_type] == 'json' && Fields[payload_name] == '${payload_name}'",
      preserve_data   => true,
      config          => {
        timeout => $timeout,
      },
      notify          => Class['lma_collector::service'],
    }
  }
}
