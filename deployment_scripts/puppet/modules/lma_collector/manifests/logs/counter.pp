# Copyright 2016 Mirantis, Inc.
#
# Licensed under the Apache License, Version 2.0 (the "License"); you may
# not use this file except in compliance with the License. You may obtain
# a copy of the License at
#
#      http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS, WITHOUT
# WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. See the
# License for the specific language governing permissions and limitations
# under the License.
#
class lma_collector::logs::counter (
  $interval = 60,
) {
  include lma_collector::params
  include lma_collector::service

  heka::filter::sandbox { 'logs_counter':
    config_dir      => $lma_collector::params::config_dir,
    filename        => "${lma_collector::params::plugins_dir}/filters/logs_counter.lua",
    message_matcher => 'Type == \'log\' && Logger =~ /^openstack\\./',
    ticker_interval => 1,
    preserve_data   => true,
    config          => {
      interval => $interval,
    },
    notify          => Class['lma_collector::service'],
  }
}
