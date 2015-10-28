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
$lma_collector  = hiera_hash('lma_collector')
$roles          = node_roles(hiera('nodes'), hiera('uid'))
$is_controller  = member($roles, 'controller') or member($roles, 'primary-controller')

$aggregator_address = hiera('management_vip')
$internal_address   = hiera('internal_address')
$management_network = hiera('management_network_range')
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
    source      => $management_network,
    destination => $internal_address,
    proto       => 'tcp',
    action      => 'accept',
  }

  # Configure the GSE filters emitting the status metrics for:
  # - service clusters
  # - node clusters
  # - global clusters
  create_resources(lma_collector::gse_cluster_filter, {
    'service' => $lma_collector['gse_cluster_service'],
    'node'    => $lma_collector['gse_cluster_node'],
    'global'  => $lma_collector['gse_cluster_global'],
  }, {
    require => Class['lma_collector::gse_policies']
  })

  class { 'lma_collector::gse_policies':
    policies => $lma_collector['gse_policies']
  }
}
