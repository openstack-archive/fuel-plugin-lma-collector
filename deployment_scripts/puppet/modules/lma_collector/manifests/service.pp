# Class: lma_collector::service
#
# Manages the LMA collector daemon
#
# Sample Usage:
#
# sometype { 'foo':
#   notify => Class['lma_collector::service'],
# }
#
#
class lma_collector::service (
  $service_name = $::lma_collector::params::service_name,
  $service_enable = true,
  $service_ensure = 'running',
  $service_manage = true,
) {
  # The base class must be included first because parameter defaults depend on it
  if ! defined(Class['lma_collector::params']) {
    fail('You must include the lma_collector::params class before using lma_collector::service')
  }

  validate_bool($service_enable)
  validate_bool($service_manage)

  case $service_ensure {
    true, false, 'running', 'stopped': {
      $_service_ensure = $service_ensure
    }
    default: {
      $_service_ensure = undef
    }
  }

  if $service_manage {
    service { 'lma_collector':
      ensure => $_service_ensure,
      name => $service_name,
      enable => $service_enable,
    }
  }
}
