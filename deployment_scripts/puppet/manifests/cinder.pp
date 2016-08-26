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

notice('fuel-plugin-lma-collector: cinder.pp')

$ceilometer      = hiera_hash('ceilometer', {})

$node_profiles   = hiera_hash('lma::collector::node_profiles')
$is_controller   = $node_profiles['controller']
$is_rabbitmq     = $node_profiles['rabbitmq']
$is_mysql_server = $node_profiles['mysql']

if $is_controller or $is_rabbitmq or $is_mysql_server {
  # On nodes where pacemaker is deployed, make sure Log and Metric collector services
  # are configured with the "pacemaker" provider
  Service<| title == 'log_collector' |> {
    provider => 'pacemaker'
  }
  Service<| title == 'metric_collector' |> {
    provider => 'pacemaker'
  }
}

if hiera('lma::collector::influxdb::server', false) {
  class { 'lma_collector::logs::counter':
    hostname => $::hostname,
  }
}

if hiera('lma::collector::elasticsearch::server', false) {
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
  value  => 'messaging',
  notify => Service[$volume_service],
}

service { $volume_service:
  hasstatus  => true,
  hasrestart => true,
}
