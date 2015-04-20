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
$lma_collector_hash = hiera('lma_collector')

if $lma_collector_hash['influxdb_mode'] != 'disabled' {
  $nodes_hash = hiera('nodes', {})
  $roles = node_roles($nodes_hash, hiera('uid'))
  # Only install this python collectd plugin if ceph-osd is deployed on a
  # dedicated node.
  if size($roles) == 1 {
    class { 'lma_collector::collectd::ceph_osd': }
  }else{
    notice('ceph_osd_perf not configured to avoid messing of collectd python plugin configuration!')
  }
}
