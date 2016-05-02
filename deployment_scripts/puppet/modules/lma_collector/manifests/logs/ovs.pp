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
class lma_collector::logs::ovs {

  include lma_collector::params
  include lma_collector::service::log

  $config_dir = $lma_collector::params::log_config_dir

  $lua_modules_dir = $lma_collector::params::lua_modules_dir

  heka::decoder::sandbox { 'ovs':
    config_dir       => $config_dir,
    filename         => "${lma_collector::params::plugins_dir}/decoders/ovs_log.lua",
    module_directory => $lua_modules_dir,
    notify           => Class['lma_collector::service::log'],
  }

  heka::input::logstreamer { 'ovs':
    config_dir     => $config_dir,
    decoder        => 'ovs',
    log_directory  => '/var/log/openvswitch',
    file_match     => '(?P<Service>ovs\-vswitchd|ovsdb\-server)\.log$',
    differentiator => '[  \'Service\' ]',
    require        => Heka::Decoder::Sandbox['ovs'],
    notify         => Class['lma_collector::service::log'],
  }
}
