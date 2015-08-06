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

  # Address and port of the Heka dashboard for health reports.
  $dashboard_address = '127.0.0.1'
  $dashboard_port    = '4352'

  $tags = {}

  $syslog_pattern = '<%PRI%>%TIMESTAMP% %HOSTNAME% %syslogtag%%msg:::sp-if-no-1st-sp%%msg%\n'
  # same pattern except the <PRI> tag
  $fallback_syslog_pattern = '%TIMESTAMP% %HOSTNAME% %syslogtag%%msg:::sp-if-no-1st-sp%%msg%\n'

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
    default: {
      fail("${::osfamily} not supported")
    }
  }
  # The maximum size of 158Kb was observed during a load test with 50 nodes,
  # this is required by elasticsearch buffered output.
  # Lets configure 192Kb by default.
  # see https://github.com/mozilla-services/heka/issues/1389
  $hekad_max_message_size = 192*1024

  # Injection of 2 messages from the filter 'service_status'
  # Heka default is 1
  $hekad_max_process_inject = 2

  # We inject as many messages than the number of OpenStack services in the Heka
  # filter 'service_accumulator_states'. Currently 10 services.
  # Hekad default is fine so far with 10 messages allowed from TimerEvent function
  $hekad_max_timer_inject = 10

  # Parameters for OpenStack notifications
  $rabbitmq_host = false
  $rabbitmq_port = '5672'
  $rabbitmq_user = ''
  $rabbitmq_password = ''
  $rabbitmq_exchange = ''
  $lma_topic = 'lma_notifications'
  $openstack_topic = 'notifications'
  $notification_driver = 'messaging'

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
  $mysql_database = ''
  $mysql_username = ''
  $mysql_password = ''
  $openstack_user = ''
  $openstack_password = ''
  $openstack_tenant = ''
  $openstack_url = 'http://127.0.0.1:5000/v2.0/'
  $openstack_client_timeout = 5
  $nova_cpu_allocation_ratio = 8.0
  $memcached_host = '127.0.0.1'

  $heartbeat_timeout = 30
  $service_status_timeout = 65
  $service_status_interval = floor($collectd_interval * 1.5)
  $service_status_payload_name = 'service_status'

  $annotations_serie_name = 'annotations'

  # Catch all metrics used to compute OpenStack service statutes
  $service_status_metrics_regexp_legacy = [
    '^openstack.(nova|cinder|neutron).(services|agents).*(up|down|disabled)$',
    # Exception for mysqld backend because the MySQL service status is
    # computed by a dedicated filter and this avoids to send an annoying
    # status Heka message.
    '^haproxy.backend.(horizon|nova|cinder|neutron|ceilometer|keystone|swift|heat|glance|radosgw)(-.+)?.servers.(down|up)$',
    '^pacemaker.resource.vip__public.active$',
    '^openstack.*check_api$'
  ]
  $service_status_metrics_matcher = join([
    '(Type == \'metric\' || Type == \'heka.sandbox.metric\') && ',
    '(Fields[name] =~ /^openstack_(nova|cinder|neutron)_(services|agents)$/ || ',
    # Exception for mysqld backend because the MySQL service status is
    # computed by a dedicated filter and this avoids to send an annoying
    # status Heka message.
    '(Fields[name] == \'haproxy_backend_servers\' && Fields[backend] !~ /mysql/) || ',
    '(Fields[name] == \'pacemaker_local_resource_active\' && Fields[resource] == \'vip__public\') || ',
    'Fields[name] =~ /^openstack.*check_api$/)'
  ], '')
  $worker_report_interval = 60
  $worker_downtime_factor = 2

  $elasticsearch_server = false
  $elasticsearch_port = '9200'

  $influxdb_server = false
  $influxdb_port = '8086'
  $influxdb_database = 'lma'
  $influxdb_user = 'lma'
  $influxdb_password = 'lmapass'
  $influxdb_timeout = 5
  $influxdb_time_precision = 'ms'

  $apache_status_host = '127.0.0.1'
  $apache_allow_from  = ['127.0.0.1','::1']

  $haproxy_names_mapping = {
    'cinder-api'          => 'cinder-api',
    'glance-api'          => 'glance-api',
    'glance-registry'     => 'glance-registry-api',
    'heat-api'            => 'heat-api',
    # Heat APIs are inverted within MOS 6.1
    # see bug https://bugs.launchpad.net/fuel/+bug/1459752
    'heat-api-cfn'        => 'heat-cloudwatch-api',
    'heat-api-cloudwatch' => 'heat-cfn-api',
    'horizon'             => 'horizon-web',
    'keystone-1'          => 'keystone-public-api',
    'keystone-2'          => 'keystone-admin-api',
    'murano'              => 'murano-api',
    'mysqld'              => 'mysqld-tcp',
    'neutron'             => 'neutron-api',
    'nova-api-1'          => 'nova-ec2-api',
    'nova-api-2'          => 'nova-api',
    'nova-novncproxy'     => 'nova-novncproxy-websocket',
    'nova-metadata-api'   => 'nova-metadata-api',
    'sahara'              => 'sahara-api',
    'swift'               => 'swift-api',
  }

  # Nagios parameters
  #
  $nagios_server = 'localhost'
  $nagios_http_port = 8001
  $nagios_http_path = 'cgi-bin/cmd.cgi'
  $nagios_user = 'nagiosadmin'
  $nagios_password = ''
  $nagios_timeout = 2

  # Following parameter must match the lma_infrastructure_alerting::params::nagios_openstack_dummy_hostname
  $nagios_hostname_service_status = '00-openstack-services'
  # Following parameter must match the lma_infrastructure_alerting::params::openstack_core_services
  $nagios_event_status_name_to_service_name_map = {
    'nova'       => 'openstack.nova.status',
    'keystone'   => 'openstack.keystone.status',
    'glance'     => 'openstack.glance.status',
    'cinder'     => 'openstack.cinder.status',
    'neutron'    => 'openstack.neutron.status',
    'heat'       => 'openstack.heat.status',
    'horizon'    => 'openstack.horizon.status',
    'swift'      => 'openstack.swift.status',
    'ceilometer' => 'openstack.ceilometer.status',
    'radosgw'    => 'openstack.radosgw.status',
  }

  # Parameters for SMTP alert of service status
  $smtp_from = 'lma-alert@localhost.localdomain'
  $smtp_subject = 'LMA Alert Notification'
  $smtp_send_interval = 0
}
