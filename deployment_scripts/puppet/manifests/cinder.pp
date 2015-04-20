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

$ceilometer    = hiera('ceilometer')
$lma_collector = hiera('lma_collector')

$enable_notifications = $lma_collector['enable_notifications']
if $ceilometer['enabled'] {
  $notification_topics = [$lma_collector::params::openstack_topic, $lma_collector::params::lma_topic]
}
else {
  $notification_topics = [$lma_collector::params::lma_topic]
}

class { 'lma_collector::logs::openstack': }

if $enable_notifications {
  class { 'lma_collector::notifications::cinder':
    topics  => $notification_topics,
  }
}
