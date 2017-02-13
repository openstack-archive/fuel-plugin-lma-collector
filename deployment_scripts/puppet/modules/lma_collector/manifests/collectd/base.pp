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
class lma_collector::collectd::base (
  $processes = undef,
  $process_matches = undef,
  $queue_limit = $lma_collector::params::collectd_queue_limit,
  $read_threads = $lma_collector::params::collectd_read_threads,
  $hostname = undef,
  $purge = false,
  $package_provider = 'apt_fuel',
) inherits lma_collector::params {

  include lma_collector::service::metric

  $type_directory = "${lma_collector::params::plugins_dir}/collectd_types/"
  $type_files = suffix(prefix($lma_collector::params::collectd_types, $type_directory), '.db')
  $lua_modules_dir = $lma_collector::params::lua_modules_dir

  file { $type_directory:
    ensure  => directory,
    source  => 'puppet:///modules/lma_collector/collectd/types',
    recurse => remote,
    before  => Class['::collectd'],
  }

  # Netlink library is required by the netlink collectd plugin
  if $::osfamily == 'RedHat' {
    $netlink_pkg_name = 'libmnl'
  } else {
    $netlink_pkg_name = 'libmnl0'
  }
  package { $netlink_pkg_name:
    ensure => present,
    before => Class['::collectd'],
  }

  $port = $lma_collector::params::collectd_port
  class { '::collectd':
    purge                  => $purge,
    recurse                => true,
    package_provider       => $package_provider,
    purge_config           => true,
    fqdnlookup             => false,
    interval               => $lma_collector::params::collectd_interval,
    threads                => $read_threads,
    write_queue_limit_low  => $lma_collector::params::collectd_queue_limit,
    write_queue_limit_high => $lma_collector::params::collectd_queue_limit,
    typesdb                => concat(['/usr/share/collectd/types.db'], $type_files)
  }

  class { 'collectd::plugin::logfile':
    log_level => 'warning',
    log_file  => $lma_collector::params::collectd_logfile,
  }

  $urls = {
    "http://127.0.0.1:${port}" => {
      'format'   => 'JSON',
      storerates => true
    }
  }
  if $::osfamily == 'RedHat' {
    # collectd Puppet manifest is broken for RedHat derivatives as it tries to
    # install the collectd-write_http package which doesn't exist (for CentOS
    # at least)
    collectd::plugin {'write_http':
      ensure  => present,
      content => template('collectd/plugin/write_http.conf.erb'),
    }
  }
  else {
    class { 'collectd::plugin::write_http':
      urls => $urls,
    }
  }

  class { 'collectd::plugin::cpu':
  }

  class { 'collectd::plugin::df':
    fstypes          => $lma_collector::params::fstypes,
    valuespercentage => true,
  }

  $block_devices = join(split($::blockdevices, ','), '|')
  class { 'collectd::plugin::disk':
    disks => [ "/^${ block_devices }$/" ],
  }

  class { 'collectd::plugin::netlink':
    verboseinterfaces => reject(grep(split($::interfaces, ','), '^[a-z0-9]+$'), '^lo$'),
  }

  class { 'collectd::plugin::load':
  }

  class { 'collectd::plugin::memory':
  }

  class { 'collectd::plugin::processes':
    processes       => $processes,
    process_matches => $process_matches,
  }

  class { 'collectd::plugin::swap':
  }

  class { 'collectd::plugin::users':
  }

  file { '/etc/logrotate.d/collectd':
    ensure  => present,
    content => "${lma_collector::params::collectd_logfile} {\n  daily\n  missingok\n}"
  }

  if $hostname {
    $real_hostname = $hostname
  }
  else {
    $real_hostname = $::hostname
  }
  heka::decoder::sandbox { 'collectd':
    config_dir       => $lma_collector::params::metric_config_dir,
    filename         => "${lma_collector::params::plugins_dir}/decoders/collectd.lua" ,
    config           => {
      hostname  => $real_hostname,
      swap_size => $::swapsize_mb * 1024 * 1024,
    },
    module_directory => $lua_modules_dir,
    notify           => Class['lma_collector::service::metric'],
  }

  heka::input::httplisten { 'collectd':
    config_dir => $lma_collector::params::metric_config_dir,
    address    => '127.0.0.1',
    port       => $port,
    decoder    => 'collectd',
    require    => Heka::Decoder::Sandbox['collectd'],
    notify     => Class['lma_collector::service::metric'],
  }
}
