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
class lma_collector::influxdb_legacy (
  $server   = $lma_collector::params::influxdb_server,
  $port     = $lma_collector::params::influxdb_port,
  $database = $lma_collector::params::influxdb_database,
  $user     = $lma_collector::params::influxdb_user,
  $password = $lma_collector::params::influxdb_password,
) inherits lma_collector::params {
  include lma_collector::service

  validate_string($server)

  heka::filter::sandbox { 'influxdb_accumulator':
    config_dir      => $lma_collector::params::config_dir,
    filename        => "${lma_collector::params::plugins_dir}/filters/influxdb_accumulator.lua",
    message_matcher => 'Type == \'metric\' || Type == \'heka.sandbox.metric\'',
    ticker_interval => 1,
    config          => {
      flush_interval => $lma_collector::params::influxdb_flush_interval,
      flush_count    => $lma_collector::params::influxdb_flush_count,
    },
    notify          => Class['lma_collector::service'],
  }

  heka::filter::sandbox { 'influxdb_annotation':
    config_dir      => $lma_collector::params::config_dir,
    filename        => "${lma_collector::params::plugins_dir}/filters/influxdb_annotation.lua",
    message_matcher => 'Type == \'heka.sandbox.status\' && Fields[updated] == TRUE',
    ticker_interval => 1,
    config          => {
      flush_interval => $lma_collector::params::influxdb_flush_interval,
      flush_count    => $lma_collector::params::influxdb_flush_count,
    },
    notify          => Class['lma_collector::service'],
  }

  heka::encoder::payload { 'influxdb':
    config_dir => $lma_collector::params::config_dir,
    notify     => Class['lma_collector::service'],
  }

  heka::output::http { 'influxdb':
    config_dir      => $lma_collector::params::config_dir,
    url             => "http://${server}:${port}/db/${database}/series",
    message_matcher => 'Fields[payload_type] == \'json\' && Fields[payload_name] == \'influxdb\'',
    username        => $user,
    password        => $password,
    timeout         => $lma_collector::params::influxdb_timeout,
    require         => [Heka::Encoder::Payload['influxdb'], Heka::Filter::Sandbox['influxdb_accumulator']],
    notify          => Class['lma_collector::service'],
  }
}
