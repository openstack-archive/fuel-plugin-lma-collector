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
class lma_collector::aggregator::server (
  $listen_address  = $lma_collector::params::aggregator_address,
  $listen_port     = $lma_collector::params::aggregator_port,
  $http_check_port = undef,
) inherits lma_collector::params {
  include lma_collector::service

  validate_string($listen_address)
  validate_integer($listen_port)

  heka::input::tcp { 'aggregator':
    config_dir => $lma_collector::params::config_dir,
    address    => $listen_address,
    port       => $listen_port,
    notify     => Class['lma_collector::service'],
  }

  if $http_check_port {
    heka::decoder::sandbox { 'http-check':
      config_dir => $lma_collector::params::config_dir,
      filename   => "${lma_collector::params::plugins_dir}/decoders/noop.lua" ,
      notify     => Class['lma_collector::service'],
    }

    heka::input::httplisten { 'http-check':
      config_dir => $lma_collector::params::config_dir,
      address    => $listen_address,
      port       => $http_check_port,
      decoder    => 'http-check',
      require    => Heka::Decoder::Sandbox['http-check'],
      notify     => Class['lma_collector::service'],
    }
  }
}
