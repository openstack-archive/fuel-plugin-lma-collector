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

$plugin_data = hiera('lma_collector', undef)

if ($plugin_data) {
  $storage_options = hiera_hash('storage', {})
  $tls_enabled = hiera('public_ssl', false)
  $ceilometer = hiera_hash('ceilometer', {})
  $ceilometer_enabled = pick($ceilometer['enabled'], false)

  $gse_filters = inline_template('---
lma_collector:
  gse_cluster_service:
    input_message_types:
      - afd_service_metric
    aggregator_flag: true
    entity_field: service
    output_message_type: gse_service_cluster_metric
    output_metric_name: cluster_service_status
    interval: 10
    level_1_dependencies:
      nova-api:
        - nova-api-backends
        - nova-ec2-api-backends
        - nova-endpoint
      nova-novncproxy:
        - nova-novncproxy-websocket-backends
      nova-metadata:
        - nova-api-metadata-backends
      nova-scheduler:
        - nova-scheduler
      nova-compute:
        - nova-compute
      nova-conductor:
        - nova-conductor
      cinder-api:
        - cinder-api-backends
        - cinder-endpoint
        - cinder-v2-endpoint
      cinder-scheduler:
        - cinder-scheduler
      cinder-volume:
        - cinder-volume
      neutron-api:
        - neutron-api-backends
        - neutron-endpoint
      neutron-l3:
        - l3
      neutron-dhcp:
        - dhcp
      neutron-ovs:
        - openvswitch
      keystone-api:
        - keystone-public-api-backends
        - keystone-admin-api-backends
        - keystone-endpoint
      glance-api:
        - glance-api-backends
        - glance-endpoint
      glance-registry:
        - glance-registry-api-backends
      heat-api:
        - heat-api-backends
        - heat-cfn-api-backends
        - heat-endpoint
      horizon-ui:
<% if @tls_enabled then -%>
        - horizon-https-backends
<% else -%>
        - horizon-web-backends
<% end -%>
<% if not @storage_options["objects_ceph"] then -%>
      swift-api:
        - swift-api-backends
        - swift-endpoint
        - swift-s3-endpoint
<% end -%>
<% if @ceilometer_enabled -%>
      ceilometer-api:
        - ceilometer-api-backends
        - ceilometer-endpoint
<% end -%>
    level_2_dependencies: {}
  gse_cluster_node:
    input_message_types:
      - afd_node_metric
    aggregator_flag: true
    entity_field: hostname
    output_message_type: gse_node_cluster_metric
    output_metric_name: cluster_node_status
    interval: 10
    level_1_dependencies: {}
    level_2_dependencies: {}
  gse_cluster_global:
    input_message_types:
      - gse_service_cluster_metric
      - gse_node_cluster_metric
    aggregator_flag: false
    entity_field: cluster_name
    output_message_type: gse_cluster_metric
    output_metric_name: cluster_status
    interval: 10
    level_1_dependencies:
      nova:
        - nova-api
        - nova-scheduler
        - nova-compute
        - nova-conductor
        - nova-novncproxy
        - nova-metadata
      cinder:
        - cinder-api
        - cinder-scheduler
        - cinder-volume
      neutron:
        - neutron-api
        - neutron-l3
        - neutron-dhcp
        - neutron-metadata
        - neutron-ovs
      keystone:
        - keystone-api
      glance:
        - glance-api
        - glance-registry
      heat:
        - heat-api
      horizon:
        - horizon-ui
<% if not @storage_options["objects_ceph"] then -%>
      swift:
        - swift-api
<% end -%>
    level_2_dependencies:
      nova-api:
        - neutron-api
        - keystone-api
        - cinder-api
        - glance-api
      cinder-api:
        - keystone-api
      neutron-api:
        - keystone-api
      glance-api:
        - keystone-api
      heat-api:
        - keystone-api
')

  lma_collector::hiera_data { 'gse_filters':
    content => $gse_filters
  }
}
