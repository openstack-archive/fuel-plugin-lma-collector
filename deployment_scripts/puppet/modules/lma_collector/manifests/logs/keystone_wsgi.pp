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
# == Class lma_collector::logs::keystone_wsgi
#
class lma_collector::logs::keystone_wsgi (
  $log_directory = $lma_collector::params::apache_log_directory,
) inherits lma_collector::params {
  include lma_collector::service::log

  $lua_modules_dir = $lma_collector::params::lua_modules_dir

  heka::decoder::sandbox { 'keystone_wsgi':
    config_dir       => $lma_collector::params::log_config_dir,
    filename         => "${lma_collector::params::plugins_dir}/decoders/keystone_wsgi_log.lua",
    config           => {
      apache_log_pattern => $lma_collector::params::apache_log_pattern,
    },
    module_directory => $lua_modules_dir,
    notify           => Class['lma_collector::service::log'],
  }

  heka::input::logstreamer { 'keystone_wsgi':
    config_dir     => $lma_collector::params::log_config_dir,
    decoder        => 'keystone_wsgi',
    log_directory  => $log_directory,
    file_match     => 'keystone_wsgi_(?P<Service>.+)_access\.log\.?(?P<Seq>\d*)$',
    differentiator => "['keystone-wsgi-', 'Service']",
    priority       => '["^Seq"]',
    require        => Heka::Decoder::Sandbox['keystone_wsgi'],
    notify         => Class['lma_collector::service::log'],
  }
}
