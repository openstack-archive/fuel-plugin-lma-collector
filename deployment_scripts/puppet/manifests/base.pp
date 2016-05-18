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
$is_controller     = roles_include(['controller', 'primary-controller'])
$is_base_os        = roles_include('base-os')
$network_metadata  = hiera_hash('network_metadata')
$detach_rabbitmq   = hiera('detach-rabbitmq', {})
$detach_database   = hiera('detach-database', {})

if $detach_database['metadata'] and $detach_database['metadata']['enabled'] {
  $is_mysql_server = roles_include(['standalone-database', 'primary-standalone-database'])
} else {
  $is_mysql_server = $is_controller
}

if $detach_rabbitmq['metadata'] and $detach_rabbitmq['metadata']['enabled'] {
  $is_rabbitmq = roles_include(['standalone-rabbitmq', 'primary-standalone-rabbitmq'])
} else {
  $is_rabbitmq = $is_controller
}

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
  openstack_roles   => join(hiera('roles'), ','),
  environment_label => $environment_label,
}

if $is_controller {
  # "keystone" group required for lma_collector::logs::openstack to be able
  # to read log files located in /var/log/keystone
  $additional_groups = ['haclient', 'keystone']
} else {
  $additional_groups = []
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

class { 'lma_collector':
  tags => $tags,
}

if $is_controller {
  $install_heka_init_script = false
} else {
  $install_heka_init_script = true
}

lma_collector::heka { 'log_collector':
  user                => $heka_user,
  groups              => $additional_groups,
  install_init_script => $install_heka_init_script,
  require             => Class['lma_collector'],
}

lma_collector::heka { 'metric_collector':
  user                => $heka_user,
  groups              => $additional_groups,
  install_init_script => $install_heka_init_script,
  require             => Class['lma_collector'],
}

# The LMA collector service is managed by Pacemaker on nodes that are
# running RabbitMQ and database in detached mode and also on controller nodes.
# We use pacemaker_wrappers::service to reconfigure the service resource
# to use the "pacemaker" service provider
if $is_controller or $is_rabbitmq or $is_mysql_server {

  $rabbitmq_resource = 'master_p_rabbitmq-server'

  if $fuel_version < 9.0 {
    pacemaker_wrappers::service { 'log_collector':
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
        'service_name' => 'log_collector',
        'config'       => '/etc/log_collector',
        'log_file'     => '/var/log/log_collector.log',
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

    if $is_rabbitmq {
      cs_rsc_colocation { "${log_service_name}-with-rabbitmq":
        ensure     => present,
        alias      => 'log_collector',
        primitives => ['clone_log_collector', $rabbitmq_resource],
        score      => 0,
        require    => Pacemaker_wrappers::Service['log_collector'],
      }

      cs_rsc_order { 'log_collector-after-rabbitmq':
        ensure  => present,
        alias   => 'log_collector',
        first   => $rabbitmq_resource,
        second  => 'clone_log_collector',
        # Heka cannot start if RabbitMQ isn't ready to accept connections. But
        # once it is initialized, it can recover from a RabbitMQ outage. This is
        # why we set score to 0 (interleave) meaning that the collector should
        # start once RabbitMQ is active but a restart of RabbitMQ
        # won't trigger a restart of the LMA collector.
        score   => 0,
        require => Cs_rsc_colocation['log_collector'],
        before  => Class['lma_collector'],
      }
    }

    pacemaker_wrappers::service { 'metric_collector':
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
        'service_name' => 'metric_collector',
        'config'       => '/etc/metric_collector',
        'log_file'     => '/var/log/metric_collector.log',
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
    pacemaker::service { 'log_collector':
      ensure           => present,
      prefix           => false,
      primitive_class  => 'ocf',
      primitive_type   => 'ocf-log_collector',
      use_handler      => false,
      complex_type     => 'clone',
      complex_metadata => {
        # the resource should start as soon as the dependent resources
        # (eg RabbitMQ) are running *locally*
        'interleave'          => true,
        'migration-threshold' => '3',
        'failure-timeout'     => '120',
      },
      parameters       => {
        'service_name' => 'log_collector',
        'config'       => '/etc/log_collector',
        'log_file'     => '/var/log/log_collector.log',
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

    if $is_rabbitmq {
      pcmk_colocation { 'log_collector-with-rabbitmq':
        ensure  => present,
        alias   => 'log_collector',
        first   => $rabbitmq_resource,
        second  => 'clone_log_collector',
        score   => 0,
        require => Pacemaker::Service['log_collector'],
      }
    }

    pacemaker::service { 'metric_collector':
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
        'service_name' => 'metric_collector',
        'config'       => '/etc/metric_collector',
        'log_file'     => '/var/log/metric_collector.log',
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

if hiera('lma::elasticsearch::is_deployed', false) {
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
    server  => hiera('lma::elasticsearch::vip'),
    port    => hiera('lma::elasticsearch::rest_port'),
    require => Class['lma_collector'],
  }

  if $is_mysql_server {
    class { 'lma_collector::logs::mysql':
      require => Class['lma_collector'],
    }
  }

  if $is_rabbitmq {
    class { 'lma_collector::logs::rabbitmq':
      require => Class['lma_collector'],
    }
  }
}

if hiera('lma::influxdb::is_deployed', false) {
  # TODO(all): this class is also applied by other role-specific manifests.
  # This is sub-optimal and error prone. It needs to be fixed by having all
  # collectd resources managed by a single manifest.
  class { 'lma_collector::collectd::base':
    processes => ['hekad', 'collectd'],
    # Purge the default configuration shipped with the collectd package
    purge     => true,
    require   => Class['lma_collector'],
  }

  if $is_mysql_server {
    $nova = hiera_hash('nova', {})

    class { 'lma_collector::collectd::mysql':
      username => 'nova',
      password => $nova['db_password'],
      require  => Class['lma_collector::collectd::base'],
    }

    lma_collector::collectd::dbi_mysql_status { 'mysql_status':
      username => 'nova',
      dbname   => 'nova',
      password => $nova['db_password'],
      require  => Class['lma_collector::collectd::base'],
    }
  }

  class { 'lma_collector::influxdb':
    server     => hiera('lma::influxdb::vip'),
    database   => hiera('lma::influxdb::database'),
    user       => hiera('lma::influxdb::user'),
    password   => hiera('lma::influxdb::password'),
    tag_fields => ['deployment_id', 'environment_label', 'tenant_id', 'user_id'],
    require    => Class['lma_collector'],
  }
}

if $is_rabbitmq {
  # OpenStack notifications are always useful for indexation and metrics
  # collection
  $messaging_address = get_network_role_property('mgmt/messaging', 'ipaddr')
  $rabbit = hiera_hash('rabbit')

  class { 'lma_collector::notifications::input':
    topic    => 'lma_notifications',
    host     => $messaging_address,
    port     => hiera('amqp_port', '5673'),
    user     => 'nova',
    password => $rabbit['password'],
  }

  if hiera('lma::influxdb::is_deployed', false) {
    class { 'lma_collector::notifications::metrics': }

    # If the node has the controller role, the collectd Python plugins will be
    # configured in controller.pp. This limitation is imposed by the upstream
    # collectd Puppet module.
    unless $is_controller {
      class { 'lma_collector::collectd::rabbitmq':
        queue   => ['/^(\\w*notifications\\.(error|info|warn)|[a-z]+|(metering|event)\.sample)$/'],
        require => Class['lma_collector::collectd::base'],
      }
    }
  }
}
