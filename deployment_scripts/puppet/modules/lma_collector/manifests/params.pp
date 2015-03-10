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
  $rabbitmq_exchange = ''
  $lma_topic = 'lma_notifications'
  $openstack_topic = 'notifications'
  $notification_driver = 'messaging'

  # collectd parameters
  $collectd_port = "8325"
  $collectd_interval = 10
  $collectd_logfile = "/var/log/collectd.log"
  case $::osfamily {
    'Debian': {
      $python_module_path = '/usr/lib/collectd'
    }
    'RedHat': {
      $python_module_path = '/usr/lib64/collectd'
    }
  }
  $additional_packages = [ 'python-dateutil' ]
  $mysql_username = ''
  $mysql_password = ''
  $rabbitmq_pid_file = '/var/run/rabbitmq/pid'
  $openstack_user = ''
  $openstack_password = ''
  $openstack_tenant = ''
  $openstack_url = "http://127.0.0.1:5000/v2.0/"
  $openstack_client_timeout = 5
  $nova_cpu_allocation_ratio = 8.0

  $elasticsearch_server = false
  $elasticsearch_port = '9200'

  $influxdb_server = false
  $influxdb_port = '8086'
  $influxdb_database = 'lma'
  $influxdb_user = 'lma'
  $influxdb_password = 'lmapass'
  $influxdb_timeout = 5
}
