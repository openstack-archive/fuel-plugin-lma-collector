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

notice('fuel-plugin-lma-collector: base.pp')

# TODO(spasquier): fail if Neutron isn't used
prepare_network_config(hiera('network_scheme', {}))
$fuel_version      = 0 + hiera('fuel_version')
$lma_collector     = hiera_hash('lma_collector')
$roles             = node_roles(hiera('nodes'), hiera('uid'))
$is_controller     = member($roles, 'controller') or member($roles, 'primary-controller')
$is_base_os        = member($roles, 'base-os')
$current_node_name = hiera('user_node_name')
$current_roles     = hiera('roles')
$network_metadata  = hiera_hash('network_metadata')

$elasticsearch_kibana = hiera_hash('elasticsearch_kibana', {})
$es_nodes = get_nodes_hash_by_roles($network_metadata, ['elasticsearch_kibana'])

$influxdb_grafana = hiera_hash('influxdb_grafana', {})
$influxdb_nodes = get_nodes_hash_by_roles($network_metadata, ['influxdb_grafana'])

if $lma_collector['environment_label'] != '' {
  $environment_label = $lma_collector['environment_label']
} else {
  $environment_label = join(['env-', hiera('deployment_id')], '')
}
$tags = {
  deployment_id     => hiera('deployment_id'),
  openstack_region  => 'RegionOne',
  openstack_release => hiera('openstack_version'),
  openstack_roles   => join($roles, ','),
  environment_label => $environment_label,
}

if $is_controller {
  # "keystone" group required for lma_collector::logs::openstack to be able
  # to read log files located in /var/log/keystone
  $additional_groups = ['haclient', 'keystone']
} else {
  $additional_groups = []
}

$elasticsearch_mode = $lma_collector['elasticsearch_mode']

case $elasticsearch_mode {
  'remote': {
    $es_server = $lma_collector['elasticsearch_address']
  }
  'local': {
    $vip_name = 'es_vip_mgmt'
    if $network_metadata['vips'][$vip_name] {
      $es_server = $network_metadata['vips'][$vip_name]['ipaddr']
    }else{
      # compatibility with elasticsearch-kibana version 0.8
      $es_server = $es_nodes[0]['internal_address']
    }
  }
  'disabled': {
    # Nothing to do
  }
  default: {
    fail("'${elasticsearch_mode}' mode not supported for Elasticsearch")
  }
}

case $::osfamily {
  'Debian': {
    $heka_user = 'heka'
  }
  'RedHat': {
    # For CentOS, the LMA collector needs to run as root because the files
    # created by RSyslog aren't created with the correct mode for now.
    $heka_user = 'root'
  }
  default: {
    fail("${::osfamily} not supported")
  }
}

if $is_controller {
  # On controller nodes the log parsing can generate a lot of http_metrics
  # which can block heka (idle packs). It was observed that a poolsize set to 200
  # solves the issue.
  $log_poolsize = 200
} else {
  # For other nodes, the poolsize is set to 100 (the Heka default value)
  $log_poolsize = 100
}

class { 'lma_collector':
  tags => $tags,
}

lma_collector::heka { 'log_collector':
  user     => $heka_user,
  groups   => $additional_groups,
  poolsize => $log_poolsize,
  require  => Class['lma_collector'],
}

lma_collector::heka { 'metric_collector':
  user    => $heka_user,
  groups  => $additional_groups,
  require => Class['lma_collector'],
}

# On controller nodes the LMA collector service is managed by Pacemaker, so we
# use pacemaker_wrappers::service to reconfigure the service resource to use
# the "pacemaker" service provider
if $is_controller {

  # TODO(all): remove this include from the manifest
  include lma_collector::params

  $log_service_name = $lma_collector::params::log_service_name
  $metric_service_name = $lma_collector::params::metric_service_name
  $log_config_dir = $lma_collector::params::log_config_dir
  $metric_config_dir = $lma_collector::params::metric_config_dir
  $rabbitmq_resource = 'master_p_rabbitmq-server'

  if $fuel_version < 9.0 {
    pacemaker_wrappers::service { $log_service_name:
      ensure          => present,
      prefix          => false,
      primitive_class => 'ocf',
      primitive_type  => 'ocf-log_collector',
      complex_type    => 'clone',
      use_handler     => false,
      ms_metadata     => {
        # the resource should start as soon as the dependent resources (eg RabbitMQ)
        # are running *locally*
        'interleave'          => true,
        'migration-threshold' => '3',
        'failure-timeout'     => '120',
      },
      parameters      => {
        'service_name' => $log_service_name,
        'config'       => $log_config_dir,
        'log_file'     => "/var/log/${log_service_name}.log",
        'user'         => $heka_user,
      },
      operations      => {
        'monitor' => {
          'interval' => '20',
          'timeout'  => '10',
        },
        'start'   => {
          'timeout' => '30',
        },
        'stop'    => {
          'timeout' => '30',
        },
      },
      ocf_script_file => 'lma_collector/ocf-lma_collector',
    }

    cs_rsc_colocation { "${log_service_name}-with-rabbitmq":
      ensure     => present,
      alias      => $log_service_name,
      primitives => ["clone_${log_service_name}", $rabbitmq_resource],
      score      => 0,
      require    => Pacemaker_wrappers::Service[$log_service_name],
    }

    cs_rsc_order { "${log_service_name}-after-rabbitmq":
      ensure  => present,
      alias   => $log_service_name,
      first   => $rabbitmq_resource,
      second  => "clone_${log_service_name}",
      # Heka cannot start if RabbitMQ isn't ready to accept connections. But
      # once it is initialized, it can recover from a RabbitMQ outage. This is
      # why we set score to 0 (interleave) meaning that the collector should
      # start once RabbitMQ is active but a restart of RabbitMQ
      # won't trigger a restart of the LMA collector.
      score   => 0,
      require => Cs_rsc_colocation[$log_service_name],
      before  => Class['lma_collector'],
    }

    pacemaker_wrappers::service { $metric_service_name:
      ensure          => present,
      prefix          => false,
      primitive_class => 'ocf',
      primitive_type  => 'ocf-metric_collector',
      complex_type    => 'clone',
      use_handler     => false,
      ms_metadata     => {
        # The resource can start at any time
        'interleave'          => false,
        'migration-threshold' => '3',
        'failure-timeout'     => '120',
      },
      parameters      => {
        'service_name' => $metric_service_name,
        'config'       => $metric_config_dir,
        'log_file'     => "/var/log/${metric_service_name}.log",
        'user'         => $heka_user,
      },
      operations      => {
        'monitor' => {
          'timeout'  => '10',
        },
        'start'   => {
          'timeout' => '30',
        },
        'stop'    => {
          'timeout' => '30',
        },
      },
      ocf_script_file => 'lma_collector/ocf-lma_collector',
    }

  } else {
    pacemaker::service { $log_service_name:
      ensure           => present,
      prefix           => false,
      primitive_class  => 'ocf',
      primitive_type   => 'ocf-log_collector',
      use_handler      => false,
      complex_type     => 'clone',
      complex_metadata => {
        # the resource should start as soon as the dependent resources (eg RabbitMQ)
        # are running *locally*
        'interleave'          => true,
        'migration-threshold' => '3',
        'failure-timeout'     => '120',
      },
      parameters       => {
        'service_name' => $log_service_name,
        'config'       => $log_config_dir,
        'log_file'     => "/var/log/${log_service_name}.log",
        'user'         => $heka_user,
      },
      operations       => {
        'monitor' => {
          'interval' => '20',
          'timeout'  => '10',
        },
        'start'   => {
          'timeout' => '30',
        },
        'stop'    => {
          'timeout' => '30',
        },
      },
      ocf_script_file  => 'lma_collector/ocf-lma_collector',
    }

    pcmk_colocation { "${log_service_name}-with-rabbitmq":
      ensure  => present,
      alias   => $log_service_name,
      first   => $rabbitmq_resource,
      second  => "clone_${log_service_name}",
      score   => 0,
      require => Pacemaker::Service[$log_service_name],
    }

    pacemaker::service { $metric_service_name:
      ensure           => present,
      prefix           => false,
      primitive_class  => 'ocf',
      primitive_type   => 'ocf-metric_collector',
      use_handler      => false,
      complex_type     => 'clone',
      complex_metadata => {
        # The resource can start at any time
        'interleave'          => false,
        'migration-threshold' => '3',
        'failure-timeout'     => '120',
      },
      parameters       => {
        'service_name' => $metric_service_name,
        'config'       => $metric_config_dir,
        'log_file'     => "/var/log/${metric_service_name}.log",
        'user'         => $heka_user,
      },
      operations       => {
        'monitor' => {
          'timeout'  => '10',
        },
        'start'   => {
          'timeout' => '30',
        },
        'stop'    => {
          'timeout' => '30',
        },
      },
      ocf_script_file  => 'lma_collector/ocf-lma_collector',
    }
  }
}

$influxdb_mode = $lma_collector['influxdb_mode']
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

  class { 'lma_collector::elasticsearch':
    server  => $es_server,
    require => Class['lma_collector'],
  }
}

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
      $influxdb_vip_name = 'influxdb'
      if $network_metadata['vips'][$influxdb_vip_name] {
        $influxdb_server = $network_metadata['vips'][$influxdb_vip_name]['ipaddr']
      } else {
        $influxdb_server = $influxdb_nodes[0]['internal_address']
      }
      $influxdb_database = $influxdb_grafana['influxdb_dbname']
      $influxdb_user = $influxdb_grafana['influxdb_username']
      $influxdb_password = $influxdb_grafana['influxdb_userpass']
    }

    if ! $is_controller {

      class { 'lma_collector::collectd::base':
        processes    => ['hekad', 'collectd'],
        read_threads => 5,
        # Purge the default configuration shipped with the collectd package
        purge        => true,
        require      => Class['lma_collector'],
      }
    }

    class { 'lma_collector::influxdb':
      server     => $influxdb_server,
      database   => $influxdb_database,
      user       => $influxdb_user,
      password   => $influxdb_password,
      tag_fields => ['deployment_id', 'environment_label', 'tenant_id', 'user_id'],
      require    => Class['lma_collector'],
    }

  }
  'disabled': {
    # Nothing to do
  }
  default: {
    fail("'${influxdb_mode}' mode not supported for InfluxDB")
  }
}
