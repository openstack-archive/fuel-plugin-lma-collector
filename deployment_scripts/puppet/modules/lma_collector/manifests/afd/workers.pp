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
class lma_collector::afd::workers () {
  include lma_collector::params

  $lua_modules_dir = $lma_collector::params::lua_modules_dir

  $metrics_matcher = join([
    '(Type == \'metric\' || Type == \'heka.sandbox.metric\')', ' && ',
    'Fields[name] =~ /^openstack_(nova|cinder|neutron)_(services|agents)$/',
  ], '')

  heka::filter::sandbox { 'afd_workers':
    config_dir       => $lma_collector::params::config_dir,
    filename         => "${lma_collector::params::plugins_dir}/filters/afd_workers.lua",
    message_matcher  => $metrics_matcher,
    module_directory => $lua_modules_dir,
    notify           => Class['lma_collector::service'],
  }
}
