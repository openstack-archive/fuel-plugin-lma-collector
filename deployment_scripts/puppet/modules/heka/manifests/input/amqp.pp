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
define heka::input::amqp (
  $config_dir,
  $decoder,
  $user,
  $password,
  $host,
  $port,
  $exchange,
  $queue,
  $exchange_durability = false,
  $exchange_auto_delete = false,
  $queue_auto_delete = true,
  $exchange_type = 'topic',
  $routing_key = '*',
  $can_exit = false,
  $ensure = present,
) {

  include heka::params

  file { "${config_dir}/amqp-${title}.toml":
    ensure  => $ensure,
    content => template('heka/input/amqp.toml.erb'),
    mode    => '0600',
    owner   => $heka::params::user,
    group   => $heka::params::user,
  }
}
