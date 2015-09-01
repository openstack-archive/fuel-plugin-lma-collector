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
$lma_collector  = hiera('lma_collector')
$roles          = node_roles(hiera('nodes'), hiera('uid'))
$is_controller  = member($roles, 'controller') or member($roles, 'primary-controller')

$aggregator_address = hiera('management_vip')
$internal_address   = hiera('internal_address')
$aggregator_port    = 5565
$check_port         = 5566

class { 'lma_collector::aggregator::client':
  address => $aggregator_address,
  port    => $aggregator_port,
}

if $is_controller {
  class { 'lma_collector::aggregator::server':
    listen_address  => $internal_address,
    listen_port     => $aggregator_port,
    http_check_port => $check_port,
  }

  # Hacks needed to leverage the haproxy_service defined type
  include haproxy::params
  Haproxy::Service { use_include => true }
  Haproxy::Balancermember { use_include => true }

  # HAProxy configuration
  openstack::ha::haproxy_service { 'lma':
    order                  => '999',
    listen_port            => $aggregator_port,
    balancermember_port    => $aggregator_port,
    haproxy_config_options => {
      'option'  => ['httpchk', 'tcplog'],
      'balance' => 'roundrobin',
      'mode'    => 'tcp',
    },
    balancermember_options => "check port ${check_port}",
    internal               => true,
    internal_virtual_ip    => $aggregator_address,
    public                 => false,
    public_virtual_ip      => undef,
    ipaddresses            => [ $internal_address ],
    server_names           => [ $::hostname ],
  }

  # Allow traffic from HAProxy to the local LMA collector
  firewall { '998 lma':
    port        => [$aggregator_port, $check_port],
    source      => $aggregator_address,
    destination => $internal_address,
    proto       => 'tcp',
    action      => 'accept',
  }

  # Configure the GSE filter emitting the cluster service metrics
  lma_collector::gse_cluster_filter { 'service':
    input_message_types  => ['afd_service_metric'],
    entity_field         => 'service',
    output_message_type  => 'gse_service_cluster_metric',
    output_metric_name   => 'cluster_service_status',
    interval             => 10,
    level_1_dependencies => {
      'nova-api'         => ['nova-api-backends', 'nova-ec2-api-backends', 'nova-novncproxy-websocket-backends',
                            'nova-endpoint'],
      'nova-metadata'    => ['nova-api-metadata-backends', 'metadata'],
      'nova-scheduler'   => ['nova-scheduler'],
      'nova-compute'     => ['nova-compute'],
      'nova-conductor'   => ['nova-conductor'],
      'cinder-api'       => ['cinder-api-backends',
                            'cinder-endpoint', 'cinder-v2-endpoint'],
      'cinder-scheduler' => ['cinder-scheduler'],
      'cinder-volume'    => ['cinder-volume'],
      'neutron-api'      => ['neutron-api-backends',
                            'neutron-endpoint'],
      'neutron-l3'       => ['l3'],
      'neutron-dhcp'     => ['dhcp'],
      'neutron-ovs'      => ['openvswitch'],
      'keystone-api'     => ['keystone-public-api-backends', 'keystone-admin-api-backends',
                            'keystone-endpoint'],
      'glance-api'       => ['glance-api-backends',
                            'glance-endpoint'],
      'glance-registry'  => ['glance-registry-backends'],
      'heat-api'         => ['heat-api-backends', 'heat-cfn-api-backends',
                            'heat-endpoint'],
    },
    level_2_dependencies => {}
  }

  # Configure the GSE filter emitting the cluster node metrics
  lma_collector::gse_cluster_filter { 'node':
    input_message_types  => ['afd_node_metric'],
    entity_field         => 'hostname',
    output_message_type  => 'gse_node_cluster_metric',
    output_metric_name   => 'cluster_node_status',
    interval             => 10,
    level_1_dependencies => {},
    level_2_dependencies => {},
  }

  # Configure the GSE filter emitting the global cluster metrics
  lma_collector::gse_cluster_filter { 'global':
    input_message_types  => ['gse_service_cluster_metric', 'gse_node_cluster_metric'],
    entity_field         => 'cluster_name',
    output_message_type  => 'gse_cluster_metric',
    output_metric_name   => 'cluster_service_status',
    interval             => 10,
    level_1_dependencies => {
      'nova'     => ['nova-api', 'nova-scheduler', 'nova-compute', 'nova-conductor'],
      'cinder'   => ['cinder-api', 'cinder-scheduler', 'cinder-volume'],
      'neutron'  => ['neutron-api', 'neutron-l3', 'neutron-dhcp', 'neutron-metadata', 'neutron-ovs'],
      'keystone' => ['keystone-api'],
      'glance'   => ['glance-api', 'glance-registry'],
      'heat'     => ['heat-api'],
    },
    level_2_dependencies => {
      'nova-api'    => ['neutron-api', 'keystone-api', 'cinder-api', 'glance-api'],
      'cinder-api'  => ['keystone-api'],
      'neutron-api' => ['keystone-api'],
      'glance-api'  => ['keystone-api'],
      'heat-api'    => ['keystone-api'],
    },
  }
}
