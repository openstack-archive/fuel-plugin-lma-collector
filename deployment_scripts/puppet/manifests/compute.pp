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
include lma_collector::params

$ceilometer    = hiera_hash('ceilometer', {})
$lma_collector = hiera_hash('lma_collector')
$roles          = node_roles(hiera('nodes'), hiera('uid'))
$is_controller  = member($roles, 'controller') or member($roles, 'primary-controller')

if $is_controller {
  # On controllers make sure the Log collector service is configured
  # with the "pacemaker" provider
  include lma_collector::params
  Service<| title == $lma_collector::params::log_service_name |> {
    provider => 'pacemaker'
  }
  Service<| title == $lma_collector::params::metric_service_name |> {
    provider => 'pacemaker'
  }
}

if $lma_collector['elasticsearch_mode'] != 'disabled' {
  lma_collector::logs::openstack { 'nova': }
  lma_collector::logs::openstack { 'neutron': }
  class { 'lma_collector::logs::libvirt': }
}

if $lma_collector['influxdb_mode'] != 'disabled' {
  class { 'lma_collector::logs::counter':
    hostname => $::hostname,
  }

  class { 'lma_collector::collectd::base':
    processes => ['hekad', 'collectd'],
  }

  class { 'lma_collector::collectd::libvirt': }
}

if $ceilometer['enabled'] {
  $notification_topics = ['notifications', 'lma_notifications']
}
else {
  $notification_topics = ['lma_notifications']
}

# OpenStack notifcations are always useful for indexation and metrics collection
include nova::params
$compute_service = $::nova::params::compute_service_name

nova_config { 'DEFAULT/notification_topics':
  value  => join($notification_topics, ','),
  notify => Service[$compute_service],
}
nova_config { 'DEFAULT/notification_driver':
  value  => 'messaging',
  notify => Service[$compute_service],
}
nova_config { 'DEFAULT/notify_on_state_change':
  value  => 'vm_and_task_state',
  notify => Service[$compute_service],
}

service { $compute_service:
  hasstatus  => true,
  hasrestart => true,
}
