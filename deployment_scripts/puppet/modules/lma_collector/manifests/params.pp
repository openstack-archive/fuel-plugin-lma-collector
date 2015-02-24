class lma_collector::params {
  $service_name = 'lma_collector'
  $config_dir = "/etc/${service_name}"
  $plugins_dir = "/usr/share/${service_name}"

  $tags = {}

  $syslog_pattern = '<%PRI%>%TIMESTAMP% %HOSTNAME% %syslogtag%%msg:::sp-if-no-1st-sp%%msg%\n'

  # required to read the log files
  case $::osfamily {
    'Debian': {
      $run_as_root = false
      $groups = ['syslog', 'adm']
    }
    'RedHat': {
      # For CentOS, the LMA collector needs to run as root because the files
      # created by RSyslog aren't created with the correct mode for now.
      $run_as_root = true
      $groups = []
    }
  }

  # Parameters for OpenStack notifications
  $rabbitmq_host = false
  $rabbitmq_user = ''
  $rabbitmq_password = ''

  $elasticsearch_server = false
  $elasticsearch_port = '9200'
}
