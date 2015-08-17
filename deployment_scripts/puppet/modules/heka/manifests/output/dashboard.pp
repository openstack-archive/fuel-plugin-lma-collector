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
define heka::output::dashboard (
  $config_dir,
  $dashboard_address = '0.0.0.0',
  $dashboard_port    = '4352',
  $ticker_interval   = '30',
  $ensure = present,
) {

  include heka::params

  file { "${config_dir}/output-${title}.toml":
    ensure  => $ensure,
    content => template('heka/output/dashboard.toml.erb'),
    mode    => '0600',
    owner   => $heka::params::user,
    group   => $heka::params::user,
  }
}

