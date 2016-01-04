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
define heka::encoder::es_json (
  $config_dir,
  $es_index_from_timestamp = false,
  $index = undef,
  $ensure = present,
  $fields = undef,
) {

  include heka::params

  if $fields != undef {
    validate_array($fields)
  }

  file { "${config_dir}/encoder-${title}.toml":
    ensure  => $ensure,
    content => template('heka/encoder/es_json.toml.erb'),
    mode    => '0600',
    owner   => $heka::params::user,
    group   => $heka::params::user,
  }
}
