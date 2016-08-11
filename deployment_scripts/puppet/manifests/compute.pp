# Copyright 2015 Mirantis, Inc.
#
# Licensed under the Apache License, Version 2.0 (the "License"); you may
# not use this file except in compliance with the License. You may obtain
# a copy of the License at
#
#      http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS, WITHOUT
# WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. See the
# License for the specific language governing permissions and limitations
# under the License.

notice('fuel-plugin-lma-collector: compute.pp')

$ceilometer = hiera_hash('ceilometer', {})

if hiera('lma::collector::elasticsearch::server', false) {
  lma_collector::logs::openstack { 'nova': }
  lma_collector::logs::openstack { 'neutron': }
  class { 'lma_collector::logs::libvirt': }
}

if hiera('lma::collector::influxdb::server', false) {
  class { 'lma_collector::logs::counter':
    hostname => $::hostname,
  }
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
