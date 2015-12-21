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
  $server = $lma_collector::params::elasticsearch_server,
  $port = $lma_collector::params::elasticsearch_port,
) inherits lma_collector::params {
  include lma_collector::service

  validate_string($server)

  heka::encoder::es_json { 'elasticsearch':
    config_dir              => $lma_collector::params::config_dir,
    index                   => '%{Type}-%{%Y.%m.%d}',
    es_index_from_timestamp => true,
    notify                  => Class['lma_collector::service'],
  }

  heka::output::elasticsearch { 'elasticsearch':
    config_dir      => $lma_collector::params::config_dir,
    server          => $server,
    port            => $port,
    message_matcher => 'Type == \'log\' || Type  == \'notification\'',
    use_buffering   => $lma_collector::params::buffering_enabled,
    max_buffer_size => $lma_collector::params::buffering_max_buffer_size,
    max_file_size   => $lma_collector::params::buffering_max_file_size,
    require         => Heka::Encoder::Es_json['elasticsearch'],
    notify          => Class['lma_collector::service'],
  }
}
