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

$lma_collector     = hiera('lma_collector')
$roles             = node_roles(hiera('nodes'), hiera('uid'))
$is_controller     = member($roles, 'controller') or member($roles, 'primary-controller')
$is_base_os        = member($roles, 'base-os')
$current_node_name = hiera('user_node_name')

$elasticsearch_kibana = hiera('elasticsearch_kibana', {})
$es_node_name = $elasticsearch_kibana['node_name']
$es_nodes = filter_nodes(hiera('nodes'), 'user_node_name', $es_node_name)

$influxdb_grafana = hiera('influxdb_grafana', {})
$influxdb_node_name = $influxdb_grafana['node_name']
$influxdb_nodes = filter_nodes(hiera('nodes'), 'user_node_name', $influxdb_node_name)

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

if hiera('deployment_mode') =~ /^ha_/ and $is_controller {
  $additional_groups = ['haclient']
}else{
  $additional_groups = []
}

$elasticsearch_mode = $lma_collector['elasticsearch_mode']

case $elasticsearch_mode {
  'remote': {
    $es_server = $lma_collector['elasticsearch_address']
  }
  'local': {
    $es_server = $es_nodes[0]['internal_address']
  }
  'disabled': {
    # Nothing to do
  }
  default: {
    fail("'${elasticsearch_mode}' mode not supported for Elasticsearch")
  }
}

# Notifications are always collected even when event indexation is disabled
if $is_controller{
  $pre_script        = '/usr/local/bin/wait_for_rabbitmq'
  # Params used by the script.
  $rabbit            = hiera('rabbit')
  $rabbitmq_port     = hiera('amqp_port', '5673')
  $rabbitmq_user     = 'nova'
  $rabbitmq_password = $rabbit['password']
  $wait_delay        = 30

  file { $pre_script:
    ensure  => present,
    owner   => 'root',
    group   => 'root',
    mode    => '0755',
    content => template('lma_collector/wait_for_rabbitmq.erb'),
    before  => Class['lma_collector']
  }
} else {
  $pre_script = undef
}

class { 'lma_collector':
  tags       => merge($tags, $additional_tags),
  groups     => $additional_groups,
  pre_script => $pre_script,
}

if $elasticsearch_mode != 'disabled' {
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

  class { 'lma_collector::elasticsearch':
    server  => $es_server,
    require => Class['lma_collector'],
  }
}

$influxdb_mode = $lma_collector['influxdb_mode']
case $influxdb_mode {
  'remote','local': {
    if $influxdb_mode == 'remote' {
      $influxdb_server = $lma_collector['influxdb_address']
      $influxdb_database = $lma_collector['influxdb_database']
      $influxdb_user = $lma_collector['influxdb_user']
      $influxdb_password = $lma_collector['influxdb_password']
    }
    else {
      # Note: we don't validate data inputs because another manifest
      # is responsible to check their coherences.
      $influxdb_server = $influxdb_nodes[0]['internal_address']
      $influxdb_database = $influxdb_grafana['influxdb_dbname']
      $influxdb_user = $influxdb_grafana['influxdb_username']
      $influxdb_password = $influxdb_grafana['influxdb_userpass']
    }

    if $is_base_os {
      if $current_node_name == $influxdb_node_name and $influxdb_mode == 'local' {
        if $lma_collector['influxdb_legacy'] {
          $processes = ['hekad', 'collectd', 'influxdb']
        } else {
          $processes = ['hekad', 'collectd', 'influxd']
        }
      } else {
        $processes = ['hekad', 'collectd']
      }

      if $current_node_name == $es_node_name and $elasticsearch_mode == 'local' {
        # Elasticsearch is running on a JVM
        $process_matches = [{name => 'elasticsearch', regex => 'java'}]
      } else {
        $process_matches = undef
      }
    } else {
      $processes = ['hekad', 'collectd']
      $process_matches = undef
    }

    if $is_controller {
      # plugins on the controllers do many network I/O operations so it is
      # recommended to increase this value.
      $collectd_read_threads = 10
    }
    else {
      $collectd_read_threads = 5
    }

    if $lma_collector['influxdb_legacy'] {
      class { 'lma_collector::collectd::base_legacy':
        processes       => $processes,
        process_matches => $process_matches,
        read_threads    => $collectd_read_threads,
        require         => Class['lma_collector'],
      }

      class { 'lma_collector::influxdb_legacy':
        server   => $influxdb_server,
        database => $influxdb_database,
        user     => $influxdb_user,
        password => $influxdb_password,
        require  => Class['lma_collector'],
      }

      class { 'lma_collector::metrics::heka_monitoring_legacy':
        require => Class['lma_collector']
      }
    } else {
      class { 'lma_collector::collectd::base':
        processes       => $processes,
        process_matches => $process_matches,
        read_threads    => $collectd_read_threads,
        require         => Class['lma_collector'],
      }

      class { 'lma_collector::influxdb':
        server   => $influxdb_server,
        database => $influxdb_database,
        user     => $influxdb_user,
        password => $influxdb_password,
        require  => Class['lma_collector'],
      }

      class { 'lma_collector::metrics::heka_monitoring':
        require => Class['lma_collector']
      }
    }

  }
  'disabled': {
    # Nothing to do
  }
  default: {
    fail("'${influxdb_mode}' mode not supported for InfluxDB")
  }
}
