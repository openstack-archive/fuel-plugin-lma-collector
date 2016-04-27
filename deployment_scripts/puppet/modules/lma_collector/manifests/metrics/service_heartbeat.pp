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
class lma_collector::metrics::service_heartbeat (
  $services,
  $timeout  = $lma_collector::params::heartbeat_timeout,
) inherits lma_collector::params {
  include lma_collector::service

  $lua_modules_dir = $lma_collector::params::lua_modules_dir

  validate_array($services)

  if (size($services) > 0) {
    heka::filter::sandbox { 'service_heartbeat':
      config_dir       => $lma_collector::params::config_dir,
      filename         => "${lma_collector::params::plugins_dir}/filters/service_heartbeat.lua",
      message_matcher  => join(['Fields[name] =~ /^', join(sort($services), '|'), '/'], ''),
      ticker_interval  => 10,
      config           => {
        timeout => $timeout,
      },
      module_directory => $lua_modules_dir,
      notify           => Class['lma_collector::service'],
    }
  }
}
