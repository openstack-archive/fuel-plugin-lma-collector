class heka::params {
  $package_name = 'heka'
  $service_name = 'hekad'
  $user = 'heka'
  $run_as_root = false
  $additional_groups = []

  $hostname = undef
  $maxprocs = $::processorcount
  $dashboard_address = undef
  $dashboard_port = '4352'

  $config_dir = "/etc/${service_name}"
  $share_dir = '/usr/share/heka'
  $lua_modules_dir = '/usr/share/heka/lua_modules'

  $wrapper = '/usr/local/bin/hekad_wrapper'

  # required to read the log files
  case $::osfamily {
    'Debian': {
      $groups = ['syslog', 'adm']
    }
    'RedHat': {
      $groups = ['adm']
    }
    default: {
      fail("${::osfamily} not supported")
    }
  }
}
