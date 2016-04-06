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
define heka::input::tcp (
  $config_dir,
  $address = '127.0.0.1',
  $port    = 5565,
  $decoder = 'ProtobufDecoder',
  $ensure  = present,
  $keep_alive = false,
  $keep_alive_period = 7200,
) {

  include heka::params

  $_keep_alive = bool2str($keep_alive)
  validate_integer($keep_alive_period)

  if $decoder == 'ProtobufDecoder' {
    $decoder_instance = $decoder
  } else {
    $decoder_instance = "${decoder}_decoder"
  }

  file { "${config_dir}/input-${title}.toml":
    ensure  => $ensure,
    content => template('heka/input/tcp.toml.erb'),
    mode    => '0600',
    owner   => $heka::params::user,
    group   => $heka::params::user,
  }
}
