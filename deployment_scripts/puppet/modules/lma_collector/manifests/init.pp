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
# The lma_collector class is able to install the common components for running
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
  $tags = $lma_collector::params::tags,
  $user = undef,
  $groups = [],
  $log_poolsize = 100,
  $metric_poolsize = 100,
) inherits lma_collector::params {
  include heka::params

  validate_hash($tags)
  validate_integer($poolsize)

  $metric_service_name = $lma_collector::params::metric_service_name
  $log_service_name = $lma_collector::params::log_service_name
  $plugins_dir = $lma_collector::params::plugins_dir
  $lua_modules_dir = $heka::params::lua_modules_dir

  $additional_groups = $user ? {
    'root'  => [],
    default => union($lma_collector::params::groups, $groups),
  }

  heka { 'metrics':
    service_name        => $metric_service_name,
    config_dir          => $lma_collector::params::metric_config_dir,
    user                => $user,
    additional_groups   => $additional_groups,
    hostname            => $::hostname,
    internal_statistics => false,
    max_message_size    => $lma_collector::params::hekad_max_message_size,
    max_process_inject  => $lma_collector::params::hekad_max_process_inject,
    max_timer_inject    => $lma_collector::params::hekad_max_timer_inject,
    poolsize            => $metric_poolsize,
  }

  heka { 'logs':
    service_name        => $log_service_name,
    config_dir          => $lma_collector::params::log_config_dir,
    user                => $user,
    additional_groups   => $additional_groups,
    hostname            => $::hostname,
    internal_statistics => false,
    max_message_size    => $lma_collector::params::hekad_max_message_size,
    max_process_inject  => $lma_collector::params::hekad_max_process_inject,
    max_timer_inject    => $lma_collector::params::hekad_max_timer_inject,
    poolsize            => $log_poolsize,
  }

  # Copy our Lua modules to Heka's modules directory so they're available for
  # the sandboxes
  file { $lua_modules_dir:
    ensure  => directory,
    source  => 'puppet:///modules/lma_collector/plugins/common',
    recurse => remote,
    notify  => [Class['lma_collector::service::metric'],
                Class['lma_collector::service::log']],
    require => [Heka['logs'], Heka['metrics']],
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

  class { 'lma_collector::service::log':
    require => Heka['logs'],
  }
  class { 'lma_collector::service::metric':
    require => Heka['metrics'],
  }
}
