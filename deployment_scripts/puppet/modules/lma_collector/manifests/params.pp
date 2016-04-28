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
class lma_collector::params {
  $service_name = 'lma_collector'
  $config_dir = "/etc/${service_name}"
  $plugins_dir = "/usr/share/${service_name}"
  $lua_modules_dir = '/usr/share/lma_collector_modules'

  $apt_config_file = '/etc/apt/apt.conf.d/99norecommends'

  $pacemaker_managed = false

  # Address and port of the Heka dashboard for health reports.
  $dashboard_address = '127.0.0.1'
  $dashboard_port    = '4352'

  $aggregator_address = '127.0.0.1'
  $aggregator_port    = 5565
  $aggregator_flag = 'aggregator'
  # matcher for the messages sent to the aggregator
  $aggregator_client_message_matcher = join([
    "Fields[${aggregator_flag}] == NIL", ' && ',
    'Type =~ /^heka\\.sandbox\\.afd.*metric$/'
  ], '')

  $watchdog_file = "/tmp/${service_name}.watchdog"
  $watchdog_payload_name = "${service_name}.watchdog"
  $watchdog_interval = 1
  $watchdog_timeout = 10 * $watchdog_interval

  $tags = {}

  $log_directory = '/var/log'
  $syslog_pattern = '<%PRI%>%TIMESTAMP% %HOSTNAME% %syslogtag%%msg:::sp-if-no-1st-sp%%msg%\n'
  # same pattern except the <PRI> tag
  $fallback_syslog_pattern = '%TIMESTAMP% %HOSTNAME% %syslogtag%%msg:::sp-if-no-1st-sp%%msg%\n'

  $apache_log_directory = '/var/log/apache2'
  $apache_log_pattern = '%{X-Forwarded-For}i %l %u %t \"%r\" %>s %b %D \"%{Referer}i\" \"%{User-Agent}i\"'

  # required to read the log files
  case $::osfamily {
    'Debian': {
      $groups = ['syslog', 'adm']
    }
    'RedHat': {
      $groups = []
    }
    default: {
      fail("${::osfamily} not supported")
    }
  }

  $buffering_enabled = true

  # Maximum size of 227Kb has been oberved by a client.
  # Lets configure 256Kb by default.
  # https://bugs.launchpad.net/lma-toolchain/+bug/1548093
  $hekad_max_message_size = 256 * 1024

  $buffering_max_file_size = 128 * 1024 * 1024
  $buffering_max_buffer_size = 1024 * 1024 * 1024

  $buffering_max_file_tiny_size = 1 * 1024 * 1024
  $buffering_max_buffer_tiny_size = 2 * 1024 * 1024

  # Heka's default value is 1
  $hekad_max_process_inject = 1

  # Heka's default value is 10
  $hekad_max_timer_inject = 10

  # Parameters for OpenStack notifications
  $rabbitmq_port = '5672'

  # collectd parameters
  $collectd_port = '8325'
  $collectd_interval = 10
  $collectd_queue_limit = 10000
  $collectd_read_threads = 5
  $collectd_logfile = '/var/log/collectd.log'
  case $::osfamily {
    'Debian': {
      $python_module_path = '/usr/lib/collectd'
      $collectd_dbi_package = 'libdbd-mysql'
    }
    'RedHat': {
      $python_module_path = '/usr/lib64/collectd'
      $collectd_dbi_package = 'libdbi-dbd-mysql'
    }
    default: {
      fail("${::osfamily} not supported")
    }
  }
  $additional_packages = [ 'python-dateutil' ]
  $openstack_user = ''
  $openstack_password = ''
  $openstack_tenant = ''
  $openstack_url = 'http://127.0.0.1:5000/v2.0/'
  $openstack_client_timeout = 5
  $nova_cpu_allocation_ratio = 16.0
  $fstypes = ['ext2', 'ext3', 'ext4', 'xfs']
  $collectd_types = [ 'ceph', 'ceph_perf' ]
  $libvirt_connection = 'qemu:///system'

  $heartbeat_timeout = 30

  $annotations_serie_name = 'annotations'

  $worker_report_interval = 60
  $worker_downtime_factor = 2

  $elasticsearch_server = false
  $elasticsearch_port = '9200'
  $elasticsearch_fields = ['Timestamp', 'Type', 'Logger', 'Severity', 'Payload', 'Pid', 'Hostname', 'DynamicFields']

  $influxdb_port = '8086'
  $influxdb_timeout = 5
  $influxdb_tag_fields = []
  $influxdb_time_precision = 'ms'
  $influxdb_message_matcher = join([
    "Fields[${aggregator_flag}] == NIL", ' && ',
    'Type =~ /metric$/'
  ], '')

  $apache_status_host = '127.0.0.1'
  $apache_status_port = '80'
  $apache_allow_from  = ['127.0.0.1','::1']

  $gse_policies_module = 'gse_policies'

  # Nagios parameters
  #
  $nagios_server = 'localhost'
  $nagios_http_port = 8001
  $nagios_http_path = 'cgi-bin/cmd.cgi'
  $nagios_user = 'nagiosadmin'
  $nagios_password = ''
  $nagios_timeout = 2

  # Following parameter must match the lma_infrastructure_alerting::params::nagios_openstack_dummy_hostname
  $nagios_hostname_for_cluster_global = '00-global-clusters'
  $nagios_hostname_for_cluster_nodes = '00-node-clusters'

  # Parameters for SMTP alert of service status
  $smtp_from = 'lma-alert@localhost.localdomain'
  $smtp_subject = 'LMA Alert Notification'
  $smtp_send_interval = 0
}
