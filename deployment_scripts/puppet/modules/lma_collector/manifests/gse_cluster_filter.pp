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
define lma_collector::gse_cluster_filter (
  $input_message_type,
  $entity_field,
  $metric_name,
  $interval = 10,
  $level_1_dependencies = {},
  $level_2_dependencies = {},
  $ensure = present,
) {
  include $lma_collector::params
  include $heka::params

  $topology_file = "gse_${title}"
  $lua_modules_dir = $heka::params::lua_modules_dir

  heka::filter::sandbox { "gse_${title}":
    config_dir      => $lma_collector::params::config_dir,
    filename        => "${lma_collector::params::plugins_dir}/filters/gse_cluster_filter.lua",
    message_matcher => "Type == '${input_message_type}' || Type == 'heka.sandbox.${input_message_type}'",
    ticker_interval => 1,
    config          => {
      metric_name   => $metric_name,
      source        => "gse_${title}_filter",
      interval      => $interval,
      topology_file => $topology_file,
      entity_field  => 'service'
    },
    require         => File[$topology_file],
    notify          => Class['lma_collector::service']
  }

  file { $topology_file:
    ensure  => present,
    path    => "${lua_modules_dir}/${topology_file}.lua",
    content => template('lma_collector/gse_topology.lua.erb'),
  }
}
