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
class lma_collector::aggregator::client (
  $address             = undef,
  $port                = $lma_collector::params::aggregator_port,
) inherits lma_collector::params {

  include lma_collector::service::metric

  if $address == undef {
    fail('address parameter should be defined!')
  }

  validate_string($address)

  heka::output::tcp { 'aggregator':
    config_dir        => $lma_collector::params::metric_config_dir,
    address           => $address,
    port              => $port,
    use_buffering     => $lma_collector::params::buffering_enabled,
    max_buffer_size   => $lma_collector::params::buffering_max_buffer_size_for_aggregator,
    max_file_size     => $lma_collector::params::buffering_max_file_size_for_aggregator,
    message_matcher   => $lma_collector::params::aggregator_client_message_matcher,
    queue_full_action => $lma_collector::params::queue_full_action_for_aggregator,
    notify            => Class['lma_collector::service::metric'],
  }
}
