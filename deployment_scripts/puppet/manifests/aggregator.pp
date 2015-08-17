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
}
