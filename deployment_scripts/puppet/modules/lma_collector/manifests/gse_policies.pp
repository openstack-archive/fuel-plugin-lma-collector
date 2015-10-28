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
class lma_collector::gse_policies (
  $policies
) {
  include heka::params
  include lma_collector::params
  include lma_collector::service

  validate_hash($policies)

  $gse_policies_path = "${heka::params::lua_modules_dir}/${lma_collector::params::gse_policies_module}.lua"

  file { 'gse_policies':
    ensure  => present,
    path    => $gse_policies_path,
    content => template('lma_collector/gse_policies.lua.erb'),
    notify  => Class['lma_collector::service'],
  }
}
