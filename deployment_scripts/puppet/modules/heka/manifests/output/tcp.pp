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
define heka::output::tcp (
  $config_dir,
  $address = '127.0.0.1',
  $port = 5565,
  $message_matcher = 'FALSE',
  $use_buffering = true,
  $queue_max_buffer_size = 1000000000, # 1GB
  $queue_full_action = 'drop',
  $max_file_size = undef,
  $ensure = present,
) {

  include heka::params

  file { "${config_dir}/output-${title}.toml":
    ensure  => $ensure,
    content => template('heka/output/tcp.toml.erb'),
    mode    => '0600',
    owner   => $heka::params::user,
    group   => $heka::params::user,
  }
}
