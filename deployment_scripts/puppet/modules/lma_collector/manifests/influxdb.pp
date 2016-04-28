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
class lma_collector::influxdb (
  $database,
  $user,
  $password,
  $server,
  $port           = $lma_collector::params::influxdb_port,
  $tag_fields     = $lma_collector::params::influxdb_tag_fields,
  $time_precision = $lma_collector::params::influxdb_time_precision,
) inherits lma_collector::params {
  include lma_collector::service

  $lua_modules_dir = $lma_collector::params::lua_modules_dir

  validate_string($database)
  validate_string($user)
  validate_string($password)
  validate_string($server)
  validate_array($tag_fields)

  heka::filter::sandbox { 'influxdb_accumulator':
    config_dir       => $lma_collector::params::config_dir,
    filename         => "${lma_collector::params::plugins_dir}/filters/influxdb_accumulator.lua",
    message_matcher  => $lma_collector::params::influxdb_message_matcher,
    ticker_interval  => 1,
    config           => {
      flush_interval => $lma_collector::params::influxdb_flush_interval,
      flush_count    => $lma_collector::params::influxdb_flush_count,
      tag_fields     => join(sort(concat(['hostname'], $tag_fields)), ' '),
      time_precision => $time_precision,
      # FIXME(pasquier-s): provide the default_tenant_id & default_user_id
      # parameters but this requires to request Keystone since we only have
      # access to the tenant name and user name for services
    },
    module_directory => $lua_modules_dir,
    notify           => Class['lma_collector::service'],
  }

  heka::filter::sandbox { 'influxdb_annotation':
    config_dir       => $lma_collector::params::config_dir,
    filename         => "${lma_collector::params::plugins_dir}/filters/influxdb_annotation.lua",
    message_matcher  => 'Type == \'heka.sandbox.gse_cluster_metric\'',
    config           => {
      serie_name => $lma_collector::params::annotations_serie_name
    },
    module_directory => $lua_modules_dir,
    notify           => Class['lma_collector::service'],
  }

  heka::encoder::payload { 'influxdb':
    config_dir => $lma_collector::params::config_dir,
    notify     => Class['lma_collector::service'],
  }

  heka::output::http { 'influxdb':
    config_dir      => $lma_collector::params::config_dir,
    url             => "http://${server}:${port}/write?db=${database}&precision=${time_precision}",
    message_matcher => 'Fields[payload_type] == \'txt\' && Fields[payload_name] == \'influxdb\'',
    username        => $user,
    password        => $password,
    timeout         => $lma_collector::params::influxdb_timeout,
    headers         => {
      'Content-Type' => 'application/x-www-form-urlencoded'
    },
    use_buffering   => $lma_collector::params::buffering_enabled,
    max_file_size   => $lma_collector::params::buffering_max_file_size,
    max_buffer_size => $lma_collector::params::buffering_max_buffer_size,
    require         => Heka::Encoder::Payload['influxdb'],
    notify          => Class['lma_collector::service'],
  }
}
