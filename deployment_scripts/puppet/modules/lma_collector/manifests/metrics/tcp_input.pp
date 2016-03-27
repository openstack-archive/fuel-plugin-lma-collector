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
class lma_collector::metrics::tcp_input (
  $listen_address  = $lma_collector::params::metric_input_address,
  $listen_port     = $lma_collector::params::metric_input_port,
) inherits lma_collector::params {
  include lma_collector::service::metric

  $config_dir = $lma_collector::params::metric_config_dir

  heka::input::tcp { 'metric':
    config_dir => $config_dir,
    address    => $listen_address,
    port       => $listen_port,
    decoder    => 'ProtobufDecoder',
    notify     => Class['lma_collector::service::metric'],
  }

}

