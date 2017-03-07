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
class lma_collector::elasticsearch (
  $server,
  $port,
  $flush_interval = 5,
  $flush_count = 10,
) {
  include lma_collector::params
  include lma_collector::service::log

  validate_string($server)
  validate_integer($port)

  heka::encoder::es_json { 'elasticsearch':
    config_dir              => $lma_collector::params::log_config_dir,
    index                   => '%{Type}-%{%Y.%m.%d}',
    es_index_from_timestamp => true,
    timestamp               => '%Y-%m-%dT%H:%M:%S%z',
    fields                  => $lma_collector::params::elasticsearch_fields,
    notify                  => Class['lma_collector::service::log'],
  }

  heka::output::elasticsearch { 'elasticsearch':
    config_dir        => $lma_collector::params::log_config_dir,
    server            => $server,
    port              => $port,
    message_matcher   => 'Type == \'log\' || Type  == \'notification\' || Type == \'audit\'',
    use_buffering     => $lma_collector::params::buffering_enabled,
    max_buffer_size   => $lma_collector::params::buffering_max_buffer_size_for_log,
    max_file_size     => $lma_collector::params::buffering_max_file_size_for_log,
    queue_full_action => $lma_collector::params::queue_full_action_for_log,
    flush_interval    => $flush_interval,
    flush_count       => $flush_count,
    require           => Heka::Encoder::Es_json['elasticsearch'],
    notify            => Class['lma_collector::service::log'],
  }
}
