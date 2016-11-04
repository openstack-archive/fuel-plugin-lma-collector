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

#
# == Class lma_collector::logs::openstack_decoder_splitter
#
# Class that sets a decoder sandbox and a token splitter for processing
# standard OpenStack service logs.
#
class lma_collector::logs::openstack_decoder_splitter {
  include lma_collector::params
  include lma_collector::service::log

  $lua_modules_dir = $lma_collector::params::lua_modules_dir

  heka::decoder::sandbox { 'openstack':
    config_dir       => $lma_collector::params::log_config_dir,
    filename         => "${lma_collector::params::plugins_dir}/decoders/openstack_log.lua",
    module_directory => $lua_modules_dir,
    config           => {
      tz => $::canonical_timezone,
    },
    notify           => Class['lma_collector::service::log'],
  }

  heka::splitter::token { 'openstack':
    config_dir => $lma_collector::params::log_config_dir,
    delimiter  => '\n',
    notify     => Class['lma_collector::service::log'],
  }
}
