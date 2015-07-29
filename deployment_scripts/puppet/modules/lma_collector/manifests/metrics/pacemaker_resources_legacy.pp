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
class lma_collector::metrics::pacemaker_resources_legacy (
  $interval = $lma_collector::params::pacemaker_resources_interval,
) inherits lma_collector::params {

  include heka::params

  file { $lma_collector::params::pacemaker_resources_script:
    ensure  => present,
    source  => 'puppet:///modules/lma_collector/pacemaker/locate_resources.sh',
    mode    => '0750',
    owner   => $heka::params::user,
    group   => $heka::params::user,
  }

  heka::splitter::token { 'pacemaker_resource':
    config_dir => $lma_collector::params::config_dir,
    delimiter  => '\n',
  }

  $pacemaker_resource_cmd = {"${lma_collector::params::pacemaker_resources_script}" => []}

  heka::input::process { 'pacemaker_resource':
    config_dir        => $lma_collector::params::config_dir,
    commands          => [$pacemaker_resource_cmd],
    decoder           => 'pacemaker_resource',
    splitter          => 'pacemaker_resource',
    ticker_interval   => $interval,
    notify            => Class['lma_collector::service'],
  }

  heka::decoder::sandbox { 'pacemaker_resource':
    config_dir  => $lma_collector::params::config_dir,
    filename    => "${lma_collector::params::plugins_dir}/decoders/pacemaker_resources_legacy.lua",
    notify      => Class['lma_collector::service'],
  }
}
