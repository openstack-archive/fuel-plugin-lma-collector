class lma_collector::collectd::base {
  include lma_collector::params
  include lma_collector::service

  $port = $lma_collector::params::collectd_port
  class { '::collectd':
    purge        => true,
    recurse      => true,
    purge_config => true,
    fqdnlookup   => false,
    interval     => $lma_collector::params::collectd_interval,
  }

  class { 'collectd::plugin::logfile':
    log_level => 'warning',
    log_file  => $lma_collector::params::collectd_logfile,
  }

  class { 'collectd::plugin::write_http':
    urls => {
      "http://127.0.0.1:${port}" => {
        'format'   => 'JSON',
        storerates => true
      }
    }
  }

  class { 'collectd::plugin::cpu':
  }

  # TODO: pass this list as a parameter or add a custom fact
  class { 'collectd::plugin::df':
    mountpoints => ['/', '/boot'],
  }

  $block_devices = join(split($::blockdevices, ','), '|')
  class { 'collectd::plugin::disk':
    disks => [ "/^${ block_devices }$/" ],
  }

  class { 'collectd::plugin::interface':
    interfaces => grep(split($::interfaces, ','), '^eth\d+$')
  }

  class { 'collectd::plugin::load':
  }

  class { 'collectd::plugin::memory':
  }

  class { 'collectd::plugin::processes':
  }

  class { 'collectd::plugin::swap':
  }

  class { 'collectd::plugin::users':
  }

  file { '/etc/logrotate.d/collectd':
    ensure  => present,
    content => "${lma_collector::params::collectd_logfile} {\n  daily\n  missingok\n}"
  }

  heka::decoder::sandbox { 'collectd':
    config_dir => $lma_collector::params::config_dir,
    filename   => "${lma_collector::params::plugins_dir}/decoders/collectd.lua" ,
    notify     => Class['lma_collector::service'],
  }

  heka::input::httplisten { 'collectd':
    config_dir => $lma_collector::params::config_dir,
    address    => '127.0.0.1',
    port       => $port,
    decoder    => 'collectd',
    require    => Heka::Decoder::Sandbox['collectd'],
    notify     => Class['lma_collector::service'],
  }
}
