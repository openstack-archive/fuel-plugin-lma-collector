class lma_collector::collectd::system {
 include lma_collector::params

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
}
