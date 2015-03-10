# Class: lma_collector::collectd::service
#
# Manages the collectd daemon
#
# Sample Usage:
#
# sometype { 'foo':
#   notify => Class['lma_collector::collectd::service'],
# }
#
#
class lma_collector::collectd::service (
  $service_enable = true,
  $service_ensure = 'running',
  $service_manage = true,
) {
  include collectd::params

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
    service { 'collectd':
      ensure => $_service_ensure,
      name => $service_name,
      enable => $service_enable,
    }
  }
}

