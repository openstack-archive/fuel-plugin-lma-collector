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

notice('fuel-plugin-lma_collector:cinder.pp')

include lma_collector::params

$ceilometer    = hiera_hash('ceilometer', {})
$lma_collector = hiera_hash('lma_collector')
$roles         = node_roles(hiera('nodes'), hiera('uid'))
$is_controller = member($roles, 'controller') or member($roles, 'primary-controller')

if $is_controller {
  # On controllers make sure the LMA service is configured
  # with the "pacemaker" provider
  include lma_collector::params
  Service<| title == $lma_collector::params::service_name |> {
    provider => 'pacemaker'
  }
}

if $lma_collector['influxdb_mode'] != 'disabled' {
  class { 'lma_collector::logs::counter':
    hostname => $::hostname,
  }
}

if $lma_collector['elasticsearch_mode'] != 'disabled' {
  lma_collector::logs::openstack { 'cinder': }
}

if $ceilometer['enabled'] {
  $notification_topics = ['notifications', 'lma_notifications']
}
else {
  $notification_topics = ['lma_notifications']
}

# OpenStack notifcations are always useful for indexation and metrics collection
include cinder::params
$volume_service = $::cinder::params::volume_service

cinder_config { 'DEFAULT/notification_topics':
  value  => join($notification_topics, ','),
  notify => Service[$volume_service],
}

cinder_config { 'DEFAULT/notification_driver':
  value  => $driver,
  notify => Service[$volume_service],
}

service { $volume_service:
  hasstatus  => true,
  hasrestart => true,
}
