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
class lma_collector::logs::hdd_errors_counter (
  $interval = 10,
  $hostname = $::hostname,
  $grace_interval = 10,
) inherits lma_collector::params {

  include lma_collector::service::log

  $lua_modules_dir = $lma_collector::params::lua_modules_dir

  heka::filter::sandbox { 'hdd_errors_counter':
    config_dir       => $lma_collector::params::log_config_dir,
    filename         => "${lma_collector::params::plugins_dir}/filters/hdd_errors_counter.lua",
    message_matcher  => 'Type == \'log\' && Logger == \'system.kern\'',
    ticker_interval  => $interval,
    config           => {
      hostname       => $hostname,
      grace_interval => $grace_interval,
      patterns       => '/error%s.+([sv]d[a-z][a-z]?)%d?/ /([sv]d[a-z][a-z]?)%d?.+%serror/',
      source         => 'log_collector',
    },
    module_directory => $lua_modules_dir,
    notify           => Class['lma_collector::service::log'],
  }
}
