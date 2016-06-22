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
# == Define: heka
#
# Install and configure the core of the Heka service.
#
# === Parameters
#
# [*config_dir*]
#   The directory where to store the configuration (default: '/etc/hekad').
#
# [*user*]
#   The user to run the Heka service as (default: 'heka'). You may have to use
#   'root' on some systems for the Heka service to be able to access log files,
#   run additional commands, ...
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
# [*max_message_size*]
#   The maxium Heka message size in bytes (default: undef to use default Heka value).
#
# [*max_process_inject*]
#   The maximum number of messages that a sandbox filter's ProcessMessage
#   function can inject in a single call (default: undef to use default Heka
#   value).
#
# [*max_timer_inject*]
#   The maximum number of messages that a sandbox filter's TimerEvent function
#   can inject in a single call (default: undef to use default Heka value).
#
# [*poolsize*]
#   The pool size of maximum messages that can exist (default: 100).
#
# [*internal_statistics*]
#   Whether or not to dump Heka internal statistics to stdout at a regular
#   interval (currently every hour).
#
# [*install_init_script*]
#   Whether or not install the init script (Upstart or Systemd). This is typically
#   used when the service is managed by Pacemaker for example.
#   (default: true).
#
# [*version*]
#   The package version to install. (default: 'latest').
#
# === Examples
#
#  class { 'heka':
#    hostname => 'foobar'
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
define heka (
  $config_dir = undef,
  $user = undef,
  $additional_groups = undef,
  $hostname = undef,
  $maxprocs = undef,
  $max_message_size = undef,
  $max_process_inject = undef,
  $max_timer_inject = undef,
  $poolsize = undef,
  $pre_script = undef,
  $internal_statistics = undef,
  $install_init_script = true,
  $version = 'latest',
) {

  include heka::params

  if $poolsize {
    validate_integer($poolsize)
  }

  $service_name = $title

  if $user {
    $heka_user = $user
  } else {
    $heka_user = $heka::params::user
  }

  if $config_dir {
    $_config_dir = $config_dir
  } else {
    $_config_dir = $heka::params::config_dir
  }

  $run_as_root = $heka_user == 'root'
  if $run_as_root {
    $_run_as_root = $run_as_root
  } else {
    $_run_as_root = $heka::params::run_as_root
  }
  if $additional_groups {
    $_additional_groups = $additional_groups
  } else {
    $_additional_groups = $heka::params::additional_groups
  }
  if $hostname {
    $_hostname = $hostname
  } else {
    $_hostname = $heka::params::hostname
  }
  if $maxprocs {
    $_maxprocs = $maxprocs
  } else {
    $_maxprocs = $heka::params::maxprocs
  }
  if $max_message_size {
    $_max_message_size = $max_message_size
  } else {
    $_max_message_size = $heka::params::max_message_size
  }
  if $max_process_inject {
    $_max_process_inject = $max_process_inject
  } else {
    $_max_process_inject = $heka::params::max_process_inject
  }
  if $max_timer_inject {
    $_max_timer_inject = $max_timer_inject
  } else {
    $_max_timer_inject = $heka::params::max_timer_inject
  }

  $hekad_wrapper = "/usr/local/bin/${service_name}_wrapper"
  $base_dir      = "/var/cache/${service_name}"
  $log_file      = "/var/log/${service_name}.log"

  if ! defined(Package[$heka::params::package_name]) {
    package { $heka::params::package_name:
      ensure => $version,
      alias  => 'heka',
    }

    if $::osfamily == 'Debian' {
      # Starting from Heka 0.10.0, the Debian package provides a SysV init
      # script so we need to stop the service and remove the init script.
      # If this script isn't removed, the user may accidentally stop *all* the
      # running hekad processes by invoking '/etc/init.d/heka stop'.
      exec { 'stop_heka_daemon':
        command => '/etc/init.d/heka stop',
        onlyif  => '/usr/bin/test -f /etc/init.d/heka',
        require => Package['heka'],
        notify  => Exec['disable_heka_daemon']
      }

      exec { 'disable_heka_daemon':
        command     => '/usr/sbin/update-rc.d heka disable',
        refreshonly => true,
        notify      => Exec['remove_heka_service'],
      }

      exec { 'remove_heka_service':
        command     => '/bin/rm -f /etc/init.d/heka',
        refreshonly => true,
      }
    }
  }

  # This Puppet User resource is used by other manifests even if the hekad
  # process runs as 'root'.
  if ! defined(User[$heka_user]) {
    user { $heka_user:
      shell  => $heka::params::nologin_bin,
      home   => $base_dir,
      system => true,
      groups => $_additional_groups,
      alias  => 'heka',
      before => Package['heka'],
    }
  }

  file { $base_dir:
    ensure  => directory,
    owner   => $heka_user,
    group   => $heka_user,
    mode    => '0750',
    require => [User[$heka_user], Package['heka']],
  }

  file { $_config_dir:
    ensure  => directory,
    owner   => $heka_user,
    group   => $heka_user,
    mode    => '0750',
    require => [User[$heka_user], Package['heka']],
  }

  file { $log_file:
    ensure  => present,
    owner   => $heka_user,
    group   => $heka_user,
    mode    => '0660',
    require => [User[$heka_user], Package['heka']],
  }

  $logrotate_conf = "/etc/logrotate_${service_name}.conf"
  file { $logrotate_conf:
    ensure  => present,
    content => template('heka/logrotate.conf.erb'),
    owner   => 'root',
    group   => 'root',
    mode    => '0644',
    require => Package['heka'],
  }

  $logrotate_bin = "/usr/local/bin/logrotate_${service_name}"
  file { $logrotate_bin:
    ensure  => present,
    owner   => 'root',
    group   => 'root',
    mode    => '0755',
    content => template('heka/logrotate.cron.erb'),
    require => File[$logrotate_conf],
  }

  cron { "${service_name} logrotate":
    ensure   => present,
    command  => $logrotate_bin,
    minute   => '*/30',
    hour     => '*',
    month    => '*',
    monthday => '*',
    require  => File[$logrotate_bin],
  }

  if $install_init_script {
    file { $hekad_wrapper:
      ensure  => present,
      owner   => 'root',
      group   => 'root',
      mode    => '0755',
      content => template('heka/hekad_wrapper.erb'),
      require => Package['heka'],
    }

    case $::osfamily {
      'Debian': {
        file {"/etc/init/${service_name}.conf":
          ensure  => present,
          content => template('heka/hekad.upstart.conf.erb'),
          notify  => Service[$service_name],
          alias   => "${service_name}_heka_init_script",
          require => File[$hekad_wrapper],
        }
      }

      'RedHat': {
        file { "/etc/init.d/${service_name}":
          ensure  => present,
          content => template('heka/hekad.initd.erb'),
          mode    => '0755',
          notify  => Service[$service_name],
          alias   => "${service_name}_heka_init_script",
          require => File[$hekad_wrapper],
        }
      }
      default: {
        fail("${::osfamily} not supported")
      }
    }
  }

  file { "${_config_dir}/global.toml":
    ensure  => present,
    content => template('heka/global.toml.erb'),
    mode    => '0600',
    owner   => $heka_user,
    group   => $heka_user,
    require => File[$_config_dir],
    notify  => Service[$service_name],
  }

  if $internal_statistics {
    cron { 'heka-internal-statistics':
      ensure   => present,
      command  => '/usr/bin/killall -SIGUSR1 hekad',
      minute   => '0',
      hour     => '*',
      month    => '*',
      monthday => '*',
    }
  }
}
