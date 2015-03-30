# Class lma_collector::logs::libvirt

class lma_collector::logs::libvirt {
  include lma_collector::params
  include lma_collector::service

  # libvirt is running as root and by default permission are restricted to
  # root user. So we need to enable other users to read this file. This works
  # if there is no logrotate.
  file { '/var/log/libvirt/libvirtd.log':
    mode => '0644',
  }

  heka::decoder::sandbox { 'libvirt':
    config_dir => $lma_collector::params::config_dir,
    filename   => "${lma_collector::params::plugins_dir}/decoders/libvirt_log.lua",
  }

  heka::input::logstreamer { 'libvirt':
    config_dir     => $lma_collector::params::config_dir,
    decoder        => 'libvirt',
    log_directory  => '/var/log/libvirt',
    file_match     => 'libvirtd.log',
    differentiator => '["libvirt"]',
    require        => Heka::Decoder::Sandbox['libvirt'],
    notify         => Class['lma_collector::service'],
  }
}
