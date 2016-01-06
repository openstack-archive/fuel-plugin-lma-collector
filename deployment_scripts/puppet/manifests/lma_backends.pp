#    Copyright 2016 Mirantis, Inc.
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

$lma_collector_hash = hiera_hash('lma_collector')

if $lma_collector_hash['influxdb_mode'] != 'disabled' {
  $network_metadata = hiera('network_metadata')
  $es_vip_name = 'es_vip_mgmt'
  $elasticsearch_vip = $network_metadata['vips'][$es_vip_name]['ipaddr']

  class { 'lma_collector::collectd::elasticsearch':
    address => $elasticsearch_vip,
  }
}
