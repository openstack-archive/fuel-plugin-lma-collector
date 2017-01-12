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
  $metric_service_name = 'metric_collector'
  $log_service_name = 'log_collector'
  $metric_config_dir = "/etc/${metric_service_name}"
  $log_config_dir = "/etc/${log_service_name}"
  $lua_modules_dir = '/usr/share/lma_collector_modules'
  # Lua plugins are shared across log and metric collectors
  $plugins_dir = '/usr/share/lma_collector'

  $pacemaker_managed = false

  # Address and port of the Heka dashboard for health reports.
  $dashboard_address = '127.0.0.1'
  $log_dashboard_port    = '4352'
  $metric_dashboard_port = '4353'

  # Address and port of the metric input
  $metric_input_address = '127.0.0.1'
  $metric_input_port = 5567

  $aggregator_address = '127.0.0.1'
  $aggregator_port    = 5565
  $aggregator_flag = 'aggregator'
  # matcher for the messages sent to the aggregator
  $aggregator_client_message_matcher = join([
    "(Fields[${aggregator_flag}] == NIL && ",
    '(Type =~ /^heka\\.sandbox\\.afd.*metric$/ || ',
    '(Fields[hostname] == NIL && Type =~ /^.*metric$/)))'], '')

  $log_watchdog_file = "/tmp/${log_service_name}.watchdog"
  $log_watchdog_payload_name = "${log_service_name}.watchdog"
  $metric_watchdog_file = "/tmp/${metric_service_name}.watchdog"
  $metric_watchdog_payload_name = "${metric_service_name}.watchdog"
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

  $buffering_max_file_size_for_metric = 128 * 1024 * 1024
  $buffering_max_buffer_size_for_metric = 1536 * 1024 * 1024
  $queue_full_action_for_metric = 'drop'

  $buffering_max_file_size_for_aggregator = 64 * 1024 * 1024
  $buffering_max_buffer_size_for_aggregator = 256 * 1024 * 1024
  $queue_full_action_for_aggregator  = 'drop'

  # The log collector should have enough room to deal with transient spikes of
  # data otherwise it may fill up the local buffer which in turn blocks the
  # Heka pipeline. Once the pipeline is stuck, it will have a hard time to
  # recover from that situation. In most cases, 1Gb should be enough.
  $buffering_max_file_size_for_log = 128 * 1024 * 1024
  $buffering_max_buffer_size_for_log = 1024 * 1024 * 1024
  $queue_full_action_for_log = 'block'

  $buffering_max_file_log_metric_size = 64 * 1024 * 1024
  $buffering_max_buffer_log_metric_size = 256 * 1024 * 1024
  $queue_full_action_for_log_metric = 'drop'

  $buffering_max_file_size_for_nagios = 512 * 1024
  $buffering_max_buffer_size_for_nagios = 1 * 1024 * 1024
  $queue_full_action_for_nagios = 'drop'

  # HTTP aggregated metrics bulk_size parameter depends on hekad_max_message_size.
  # The bulk_size is calculated considering that one metric bucket is a string
  # of 300B size and we pick 60% of the theorical value.
  # With the hekad_max_message_size set to 256KB, the bulk_size is 524 metrics.
  $http_aggregated_metrics_bulk_size = floor($hekad_max_message_size / 300 * 0.6)

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
  $fstypes = ['ext2', 'ext3', 'ext4', 'xfs', 'tmpfs']
  $collectd_types = [ 'ceph', 'ceph_perf' ]
  $libvirt_connection = 'qemu:///system'

  $heartbeat_timeout = 30

  $annotations_serie_name = 'annotations'

  $worker_report_interval = 60
  $worker_downtime_factor = 2

  $elasticsearch_fields = ['Timestamp', 'Type', 'Logger', 'Severity', 'Payload', 'Pid', 'Hostname', 'DynamicFields']

  $influxdb_timeout = 5
  $influxdb_flush_interval = 5
  # InfluxDB recommends a batch size of 5,000 points but we are limited to 400
  # due to the hekad_max_message_size. The limit is reached when the influxdb
  # accumulator inject data points.
  $influxdb_flush_count = 400
  $influxdb_tag_fields = []
  $influxdb_time_precision = 'ms'
  $influxdb_message_matcher = join([
    "Fields[${aggregator_flag}] == NIL", ' && ',
    'Type =~ /metric$/'
  ], '')

  $apache_status_host = '127.0.0.1'
  $apache_status_port = '80'

  $gse_policies_module = 'gse_policies'

  # Nagios parameters
  #
  $nagios_timeout = 2

  # Parameters for SMTP alert of service status
  $smtp_from = 'lma-alert@localhost.localdomain'
  $smtp_send_interval = 0
}
