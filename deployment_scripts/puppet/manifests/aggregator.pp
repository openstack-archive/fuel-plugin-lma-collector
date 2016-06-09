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

notice('fuel-plugin-lma-collector: aggregator.pp')

prepare_network_config(hiera_hash('network_scheme', {}))
$mgmt_address    = get_network_role_property('management', 'ipaddr')
$lma_collector   = hiera_hash('lma_collector')

$node_profiles   = hiera_hash('lma::collector::node_profiles')
$is_controller   = $node_profiles['controller']
$is_mysql_server = $node_profiles['mysql']
$is_rabbitmq     = $node_profiles['rabbitmq']

$network_metadata = hiera_hash('network_metadata')
$controllers      = get_nodes_hash_by_roles($network_metadata, ['primary-controller', 'controller'])

$aggregator_address = hiera('management_vip')
$management_network = hiera('management_network_range')
$aggregator_port    = 5565
$check_port         = 5566

if $is_controller or $is_rabbitmq or $is_mysql_server {
  # On nodes where pacemaker is deployed, make sure the Log and Metric collector services
  # are configured with the "pacemaker" provider
  Service<| title == 'log_collector' |> {
    provider => 'pacemaker'
  }
  Service<| title == 'metric_collector' |> {
    provider => 'pacemaker'
  }
}

# On a dedicated environment, without controllers, we don't deploy the
# aggregator client.
if size(keys($controllers)) > 0 {
  class { 'lma_collector::aggregator::client':
    address => $aggregator_address,
    port    => $aggregator_port,
  }
}

if $is_controller {
  class { 'lma_collector::aggregator::server':
    listen_address  => $mgmt_address,
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
    ipaddresses            => [ $mgmt_address ],
    server_names           => [ $::hostname ],
  }

  # Allow traffic from HAProxy to the local LMA collector
  firewall { '998 lma':
    port        => [$aggregator_port, $check_port],
    source      => $management_network,
    destination => $mgmt_address,
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
