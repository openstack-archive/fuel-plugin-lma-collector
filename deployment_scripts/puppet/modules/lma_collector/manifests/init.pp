# == Class: lma_collector
#
# The lma_collector class is able to install the common components for running
# the Logging, Monitoring and Alerting collector service.
#
# === Parameters
#
# === Examples
#
# === Authors
#
# Simon Pasquier <spasquier@mirantis.com>
#
# === Copyright
#
# Copyright 2015 Mirantis Inc., unless otherwise noted.
#
class lma_collector (
  $tags = $lma_collector::params::tags,
  $groups = [],
) inherits lma_collector::params {
  include heka::params
  include lma_collector::service

  validate_hash($tags)

  $service_name = $lma_collector::params::service_name
  $config_dir = $lma_collector::params::config_dir
  $plugins_dir = $lma_collector::params::plugins_dir
  $lua_modules_dir = $heka::params::lua_modules_dir
  $wait_for_rabbitmq = $lma_collector::params::wait_for_rabbitmq
  $wait_delay = $lma_collector::params::wait_delay

  class { 'heka':
    service_name      => $service_name,
    config_dir        => $config_dir,
    run_as_root       => $lma_collector::params::run_as_root,
    additional_groups => union($lma_collector::params::groups, $groups),
    hostname          => $::hostname,
    pre_script        => $wait_for_rabbitmq,
    require           => File[$wait_for_rabbitmq],
  }

  file { $wait_for_rabbitmq:
    ensure  => present,
    owner   => 'root',
    group   => 'root',
    mode    => '0755',
    content => template('lma_collector/wait_for_rabbitmq.erb'),
  }

  file { "${lua_modules_dir}/lma_utils.lua":
    ensure  => directory,
    source  => 'puppet:///modules/lma_collector/plugins/common/lma_utils.lua',
    require => File[$lua_modules_dir],
    notify => Class['lma_collector::service'],
  }

  file { "${lua_modules_dir}/patterns.lua":
    ensure  => directory,
    source  => 'puppet:///modules/lma_collector/plugins/common/patterns.lua',
    require => File[$lua_modules_dir],
    notify => Class['lma_collector::service'],
  }

  file { "${lua_modules_dir}/extra_fields.lua":
    ensure  => present,
    content => template('lma_collector/extra_fields.lua.erb'),
    require => File[$lua_modules_dir],
    notify => Class['lma_collector::service'],
  }

  file { $plugins_dir:
    ensure => directory,
  }

  file { "${plugins_dir}/decoders":
    ensure  => directory,
    source  => 'puppet:///modules/lma_collector/plugins/decoders',
    recurse => remote,
    notify  => Class['lma_collector::service'],
    require => File[$plugins_dir]
  }

  file { "${plugins_dir}/filters":
    ensure  => directory,
    source  => 'puppet:///modules/lma_collector/plugins/filters',
    recurse => remote,
    notify  => Class['lma_collector::service'],
    require => File[$plugins_dir]
  }

  if size($lma_collector::params::additional_packages) > 0 {
    package { $lma_collector::params::additional_packages:
      ensure => present,
    }
  }
}
