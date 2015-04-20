#    Copyright 2014 Mirantis, Inc.
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
# == Class: heka
#
# Install and configure the core of the Heka service.
#
# === Parameters
#
# [*service_name*]
#   The name of the service daemon (default: 'hekad').
#
# [*config_dir*]
#   The directory where to store the configuration (default: '/etc/hekad').
#
# [*run_as_root*]
#   Whether or not to run the Heka service as root (default: false).
#   You may have to set this parameter to true on some systems to access log
#   files, run additional commands, ...
#
# [*additional_groups*]
#   Additional groups to which the heka user should be added.
#
# [*hostname*]
#   Hostname reported by the service in the messages (default: the host's FQDN).
#
# [*maxprocs*]
#   The number of CPU cores (default: $processorcount).
#
# [*dashboard_address*]
#   The listening adddress for the Heka dashboard (default: undef).
#
# [*dashboard_port*]
#   The listening port for the Heka dashboard (default: 4352).
#
# === Examples
#
#  class { 'heka':
#    hostname => 'foobar'
#    dashboard_address => '127.0.0.1',
#  }
#
# === Authors
#
# Simon Pasquier <spasquier@mirantis.com>
#
# === Copyright
#
# Copyright 2015 Mirantis Inc, unless otherwise noted.
#
class heka (
  $service_name = $heka::params::service_name,
  $config_dir = $heka::params::config_dir,
  $run_as_root = $heka::params::run_as_root,
  $additional_groups = $heka::params::additional_groups,
  $hostname = $heka::params::hostname,
  $maxprocs = $heka::params::maxprocs,
  $dashboard_address = $heka::params::dashboard_address,
  $dashboard_port = $heka::params::dashboard_port,
) inherits heka::params {

  $heka_user = $heka::params::user
  $base_dir = "/var/cache/${service_name}"
  $log_file = "/var/log/${service_name}.log"

  package { $heka::params::package_name:
    ensure => present,
    alias  => 'heka',
  }

  file { $heka::params::lua_modules_dir:
    ensure  => directory,
    require => Package['heka'],
  }

  user { $heka_user:
    shell  => '/sbin/nologin',
    home   => $base_dir,
    system => true,
    groups => $additional_groups,
    alias  => 'heka',
  }

  file { $base_dir:
    ensure  => directory,
    owner   => $heka_user,
    group   => $heka_user,
    mode    => '0750',
    require => [User['heka'], Package['heka']],
  }

  file { $config_dir:
    ensure  => directory,
    owner   => $heka_user,
    group   => $heka_user,
    mode    => '0750',
    require => [User['heka'], Package['heka']],
  }

  file { $log_file:
    ensure  => present,
    owner   => $heka_user,
    group   => $heka_user,
    mode    => '0660',
    require => [User['heka'], Package['heka']],
  }

  file { "/etc/logrotate.d/${service_name}":
    ensure  => present,
    content => template('heka/logrotate.conf.erb'),
  }

  case $::osfamily {
    'Debian': {
      file {"/etc/init/${service_name}.conf":
        ensure  => present,
        content => template('heka/hekad.upstart.conf.erb'),
        notify  => Service[$service_name],
        alias   => 'heka_init_script',
      }
    }

    'RedHat': {
      file { "/etc/init.d/${service_name}":
        ensure  => present,
        content => template('heka/hekad.initd.erb'),
        mode    => '0755',
        notify  => Service[$service_name],
        alias   => 'heka_init_script',
      }
    }
    default: {
      fail("${::osfamily} not supported")
    }
  }

  file { "${config_dir}/global.toml":
    ensure  => present,
    content => template('heka/global.toml.erb'),
    mode    => '0600',
    owner   => $heka_user,
    group   => $heka_user,
    require => File[$config_dir],
    notify  => Service[$service_name],
  }

  if $dashboard_address {
    file { "${config_dir}/dashboard.toml":
      ensure  => present,
      content => template('heka/output/dashboard.toml.erb'),
      mode    => '0600',
      owner   => $heka_user,
      group   => $heka_user,
      require => File[$config_dir],
      notify  => Service[$service_name],
    }
  }
}
