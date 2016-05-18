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
# == Class: lma_collector
#
# The lma_collector class installs the common Lua modules used by
# the Logging, Monitoring and Alerting collector services.
#
# === Parameters
#
# === Examples
#
# === Authors
#
# Simon Pasquier <spasquier@mirantis.com>
# Swann Croiset <scroiset@mirantis.com>
#
# === Copyright
#
# Copyright 2016 Mirantis Inc., unless otherwise noted.
#
class lma_collector (
  $tags = {},
) {
  include lma_collector::params
  include lma_collector::service::log
  include lma_collector::service::metric

  validate_hash($tags)

  $plugins_dir = $lma_collector::params::plugins_dir
  $lua_modules_dir = $lma_collector::params::lua_modules_dir

  file { $lua_modules_dir:
    ensure  => directory,
    source  => 'puppet:///modules/lma_collector/plugins/common',
    recurse => remote,
    notify  => [Class['lma_collector::service::metric'],
                Class['lma_collector::service::log']],
  }

  file { "${lua_modules_dir}/extra_fields.lua":
    ensure  => present,
    content => template('lma_collector/extra_fields.lua.erb'),
    require => File[$lua_modules_dir],
    notify  => [Class['lma_collector::service::metric'],
                Class['lma_collector::service::log']],
  }

  file { $plugins_dir:
    ensure => directory,
  }

  file { "${plugins_dir}/decoders":
    ensure  => directory,
    source  => 'puppet:///modules/lma_collector/plugins/decoders',
    recurse => remote,
    notify  => [Class['lma_collector::service::metric'],
                Class['lma_collector::service::log']],
    require => File[$plugins_dir]
  }

  file { "${plugins_dir}/filters":
    ensure  => directory,
    source  => 'puppet:///modules/lma_collector/plugins/filters',
    recurse => remote,
    notify  => [Class['lma_collector::service::metric'],
                Class['lma_collector::service::log']],
    require => File[$plugins_dir]
  }

  file { "${plugins_dir}/encoders":
    ensure  => directory,
    source  => 'puppet:///modules/lma_collector/plugins/encoders',
    recurse => remote,
    notify  => [Class['lma_collector::service::metric'],
                Class['lma_collector::service::log']],
    require => File[$plugins_dir]
  }

  file { "${plugins_dir}/outputs":
    ensure  => directory,
    source  => 'puppet:///modules/lma_collector/plugins/outputs',
    recurse => remote,
    notify  => [Class['lma_collector::service::metric'],
                Class['lma_collector::service::log']],
    require => File[$plugins_dir]
  }

  if size($lma_collector::params::additional_packages) > 0 {
    package { $lma_collector::params::additional_packages:
      ensure => present,
    }
  }
}
