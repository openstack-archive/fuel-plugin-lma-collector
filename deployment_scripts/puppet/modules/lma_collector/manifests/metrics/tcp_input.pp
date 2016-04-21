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
  $deserialize_bulk_metric_for_loggers = undef,
) inherits lma_collector::params {
  include lma_collector::service::metric

  $config_dir = $lma_collector::params::metric_config_dir

  if $deserialize_bulk_metric_for_loggers {
    validate_string($deserialize_bulk_metric_for_loggers)
    $decoder_config = { deserialize_bulk_metric_for_loggers => $deserialize_bulk_metric_for_loggers }
  } else {
    $decoder_config = {}
  }

  heka::decoder::sandbox { 'metric':
    config_dir => $config_dir,
    filename   => "${lma_collector::params::plugins_dir}/decoders/metric.lua",
    config     => $decoder_config,
    notify     => Class['lma_collector::service::metric'],
  }

  heka::input::tcp { 'metric':
    config_dir => $config_dir,
    address    => $listen_address,
    port       => $listen_port,
    decoder    => 'metric',
    keep_alive => true,
    require    => Heka::Decoder::Sandbox['metric'],
    notify     => Class['lma_collector::service::metric'],
  }

}

