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
# TODO(spasquier): fail if Neutron isn't used

$lma_collector = hiera('lma_collector')
$roles         = node_roles(hiera('nodes'), hiera('uid'))

$tags = {
  deployment_id => hiera('deployment_id'),
  deployment_mode => hiera('deployment_mode'),
  openstack_region => 'RegionOne',
  openstack_release => hiera('openstack_version'),
  openstack_roles => join($roles, ','),
}
if $lma_collector['environment_label'] != '' {
  $additional_tags = {
    environment_label => $lma_collector['environment_label'],
  }
}
else {
  $additional_tags = {}
}

if hiera('deployment_mode') =~ /^ha_/ and hiera('role') =~ /controller/{
  $additional_groups = ['haclient']
}else{
  $additional_groups = []
}

class { 'lma_collector':
  tags   => merge($tags, $additional_tags),
  groups => $additional_groups,
}

class { 'lma_collector::logs::system':
  require => Class['lma_collector'],
}

if (str2bool($::ovs_log_directory)){
  # install logstreamer for open vSwitch if log directory exists
  class { 'lma_collector::logs::ovs':
    require => Class['lma_collector'],
  }
}

class { 'lma_collector::logs::monitor':
  require => Class['lma_collector'],
}

$influxdb_mode = $lma_collector['influxdb_mode']
case $influxdb_mode {
  'remote','local': {
    if $influxdb_mode == 'remote' {
      $influxdb_server = $lma_collector['influxdb_address']
    }
    else {
      $influxdb_node_name = $lma_collector['influxdb_node_name']
      $influxdb_nodes = filter_nodes(hiera('nodes'), 'user_node_name', $influxdb_node_name)
      if size($influxdb_nodes) < 1 {
        fail("Could not find node '${influxdb_node_name}' in the environment")
      }
      $influxdb_server = $influxdb_nodes[0]['internal_address']
    }

    class { 'lma_collector::collectd::base':
    }

    class { 'lma_collector::influxdb':
      server   => $influxdb_server,
      database => $lma_collector['influxdb_database'],
      user     => $lma_collector['influxdb_user'],
      password => $lma_collector['influxdb_password'],
    }
  }
  'disabled': {
    # Nothing to do
  }
  default: {
    fail("'${influxdb_mode}' mode not supported for InfluxDB")
  }
}

$elasticsearch_mode = $lma_collector['elasticsearch_mode']
case $elasticsearch_mode {
  'remote': {
    $es_server = $lma_collector['elasticsearch_address']
  }
  'local': {
    $es_node_name = $lma_collector['elasticsearch_node_name']
    $es_nodes = filter_nodes(hiera('nodes'), 'user_node_name', $es_node_name)
    if size($es_nodes) < 1 {
      fail("Could not find node '${es_node_name}' in the environment")
    }
    $es_server = $es_nodes[0]['internal_address']
  }
  default: {
    fail("'${elasticsearch_mode}' mode not supported for ElasticSearch")
  }
}

class { 'lma_collector::elasticsearch':
  server => $es_server,
  require => Class['lma_collector'],
}
