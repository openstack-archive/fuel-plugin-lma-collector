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
class lma_collector::metrics::tcp_output (
  $address  = $lma_collector::params::metric_input_address,
  $port     = $lma_collector::params::metric_input_port,
) inherits lma_collector::params {
  include lma_collector::service::metric

  $config_dir = $lma_collector::params::log_config_dir

  heka::output::tcp { 'metric':
    config_dir        => $config_dir,
    address           => $address,
    port              => $port,
    message_matcher   => '(Type == \'metric\' || Type == \'heka.sandbox.metric\' || Type == \'heka.sandbox.bulk_metric\')',
    keep_alive        => true,
    max_buffer_size   => $lma_collector::params::buffering_max_buffer_log_metric_size,
    max_file_size     => $lma_collector::params::buffering_max_file_log_metric_size,
    queue_full_action => $lma_collector::params::queue_full_action_log_metric,
    notify            => Class['lma_collector::service::log'],
  }

}


