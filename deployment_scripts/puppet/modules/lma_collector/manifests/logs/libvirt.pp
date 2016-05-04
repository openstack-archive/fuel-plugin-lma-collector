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
# Class lma_collector::logs::libvirt

class lma_collector::logs::libvirt {

  include lma_collector::params
  include lma_collector::service::log

  $config_dir = $lma_collector::params::log_config_dir

  $libvirt_dir       = '/var/log/libvirt'
  $libvirt_log       = 'libvirtd.log'
  $libvirt_hooks_dir = '/etc/libvirt/hooks'
  $libvirt_hook      = "${libvirt_hooks_dir}/daemon"
  $libvirt_service   = $::libvirt_daemon
  $lua_modules_dir   = $lma_collector::params::lua_modules_dir

  service {$libvirt_service: }

  file { $libvirt_hooks_dir:
    ensure => 'directory',
  }

  # libvirt is running as root and by default permission are restricted to
  # root user. So we need to enable other users to read this file.
  file { $libvirt_hook:
    owner   => 'root',
    group   => 'root',
    mode    => '0700',
    content => template('lma_collector/hooks_daemon.erb'),
    require => File[$libvirt_hooks_dir],
    notify  => Service[$libvirt_service],
  }

  heka::decoder::sandbox { 'libvirt':
    config_dir       => $config_dir,
    filename         => "${lma_collector::params::plugins_dir}/decoders/libvirt_log.lua",
    module_directory => $lua_modules_dir,
    notify           => Class['lma_collector::service::log'],
  }

  heka::input::logstreamer { 'libvirt':
    config_dir     => $config_dir,
    log_directory  => $libvirt_dir,
    file_match     => $libvirt_log,
    decoder        => 'libvirt',
    differentiator => '["libvirt"]',
    require        => Heka::Decoder::Sandbox['libvirt'],
    notify         => Class['lma_collector::service::log'],
  }
}
