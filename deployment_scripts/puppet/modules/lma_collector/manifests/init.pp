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
  $pre_script = undef,
  $pacemaker_managed = $lma_collector::params::pacemaker_managed,
  $rabbitmq_resource = undef,
  $aggregator_address = undef,
  $aggregator_port = $lma_collector::params::aggregator_port,
) inherits lma_collector::params {
  include heka::params

  validate_hash($tags)

  $service_name = $lma_collector::params::service_name
  $config_dir = $lma_collector::params::config_dir
  $plugins_dir = $lma_collector::params::plugins_dir
  $lua_modules_dir = $heka::params::lua_modules_dir

  class { 'heka':
    service_name        => $service_name,
    config_dir          => $config_dir,
    run_as_root         => $lma_collector::params::run_as_root,
    additional_groups   => union($lma_collector::params::groups, $groups),
    hostname            => $::hostname,
    pre_script          => $pre_script,
    internal_statistics => true,
    max_message_size    => $lma_collector::params::hekad_max_message_size,
    max_process_inject  => $lma_collector::params::hekad_max_process_inject,
    max_timer_inject    => $lma_collector::params::hekad_max_timer_inject,
  }

  if $pacemaker_managed {
    validate_string($rabbitmq_resource)

    if $lma_collector::params::run_as_root {
      $heka_user = 'root'
    } else {
      $heka_user = $heka::params::user
    }

    file { 'ocf-lma_collector':
      ensure => present,
      path   => '/usr/lib/ocf/resource.d/fuel/ocf-lma_collector',
      source => 'puppet:///modules/lma_collector/ocf-lma_collector',
      mode   => '0755',
      owner  => 'root',
      group  => 'root',
    }

    cs_resource { $service_name:
      primitive_class => 'ocf',
      provided_by     => 'fuel',
      primitive_type  => 'ocf-lma_collector',
      complex_type    => 'clone',
      ms_metadata     => {
        # the resource should start as soon as the dependent resources (eg
        # RabbitMQ) are running *locally*
        'interleave' => true,
      },
      parameters      => {
        'config'   => $config_dir,
        'log_file' => "/var/log/${service_name}.log",
        'user'     => $heka_user,
      },
      operations      => {
        'monitor' => {
          'interval' => '10s',
          'timeout'  => '30s',
        },
        'start'   => {
          'timeout' => '30s',
        },
        'stop'    => {
          'timeout' => '30s',
        },
      },
      require         => [File['ocf-lma_collector'], Class['heka']],
    }

    cs_rsc_colocation { "${service_name}-with-rabbitmq":
      ensure     => present,
      alias      => $service_name,
      primitives => ["clone_${service_name}", $rabbitmq_resource],
      score      => 0,
      require    => Cs_resource[$service_name],
    }

    cs_rsc_order { "${service_name}-after-rabbitmq":
      ensure  => present,
      alias   => $service_name,
      first   => $rabbitmq_resource,
      second  => "clone_${service_name}",
      # Heka cannot start if RabbitMQ isn't ready to accept connections. But
      # once it is initialized, it can recover from a RabbitMQ outage. This is
      # why we set score to 0 (interleave) meaning that the collector should
      # start once RabbitMQ is active but a restart of RabbitMQ
      # won't trigger a restart of the LMA collector.
      score   => 0,
      require => Cs_rsc_colocation[$service_name]
    }

    class { 'lma_collector::service':
      provider => 'pacemaker',
      require  => Cs_rsc_order[$service_name]
    }
  } else {
    # Use the default service class
    include lma_collector::service
  }

  file { "${lua_modules_dir}/common":
    ensure  => directory,
    source  => 'puppet:///modules/lma_collector/plugins/common',
    recurse => remote,
    notify  => Class['lma_collector::service'],
    require => File[$lua_modules_dir],
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

  file { "${plugins_dir}/encoders":
    ensure  => directory,
    source  => 'puppet:///modules/lma_collector/plugins/encoders',
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
