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

$heka_version = '0.10.0'

# TODO(spasquier): fail if Neutron isn't used
prepare_network_config(hiera_hash('network_scheme', {}))
$fuel_version    = 0 + hiera('fuel_version')
$lma_collector   = hiera_hash('lma_collector')

$node_profiles   = hiera_hash('lma::collector::node_profiles')
$is_controller   = $node_profiles['controller']
$is_base_os      = $node_profiles['base_os']
$is_mysql_server = $node_profiles['mysql']
$is_rabbitmq     = $node_profiles['rabbitmq']

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
  # On controller nodes the increase of the AFD filters puts too much load on
  # the heka pipeline which can block heka (idle packs).
  # It was observed that a poolsize set to 200 solves the issue.
  $poolsize = 200
} else {
  $install_heka_init_script = true
  $poolsize = 100
}

lma_collector::heka { 'log_collector':
  user                => $heka_user,
  groups              => $additional_groups,
  install_init_script => $install_heka_init_script,
  version             => $heka_version,
  heka_monitoring     => false,
  require             => Class['lma_collector'],
}

lma_collector::heka { 'metric_collector':
  user                => $heka_user,
  groups              => $additional_groups,
  install_init_script => $install_heka_init_script,
  version             => $heka_version,
  poolsize            => $poolsize,
  heka_monitoring     => false,
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
      primitive_type  => 'ocf-lma_collector',
      complex_type    => 'clone',
      use_handler     => false,
      ms_metadata     => {
        # the resource should start as soon as the dependent resources (eg RabbitMQ)
        # are running *locally*
        'interleave' => true,
      },
      metadata        => {
        # Make sure that Pacemaker tries to restart the resource if it fails
        # too many times
        'failure-timeout'     => '120s',
        'migration-threshold' => '3',
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
      primitive_type  => 'ocf-lma_collector',
      complex_type    => 'clone',
      use_handler     => false,
      ms_metadata     => {
        # The resource can start at any time
        'interleave' => false,
      },
      metadata        => {
        # Make sure that Pacemaker tries to restart the resource if it fails
        # too many times
        'failure-timeout'     => '120s',
        'migration-threshold' => '3',
      },
      parameters      => {
        'service_name' => 'metric_collector',
        'config'       => '/etc/metric_collector',
        'log_file'     => '/var/log/metric_collector.log',
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
    }
  } else {
    pacemaker::service { 'log_collector':
      ensure           => present,
      prefix           => false,
      primitive_class  => 'ocf',
      primitive_type   => 'ocf-lma_collector',
      use_handler      => false,
      complex_type     => 'clone',
      complex_metadata => {
        # the resource should start as soon as the dependent resources
        # (eg RabbitMQ) are running *locally*
        'interleave' => true,
      },
      metadata         => {
        # Make sure that Pacemaker tries to restart the resource if it fails
        # too many times
        'failure-timeout'     => '120s',
        'migration-threshold' => '3',
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
      require          => Lma_collector::Heka['log_collector'],
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

      pcmk_order { 'log_collector-after-rabbitmq':
        ensure  => present,
        first   => $rabbitmq_resource,
        second  => 'clone_log_collector',
        # Heka cannot start if RabbitMQ isn't ready to accept connections. But
        # once it is initialized, it can recover from a RabbitMQ outage. This is
        # why we set score to 0 (interleave) meaning that the collector should
        # start once RabbitMQ is active but a restart of RabbitMQ
        # won't trigger a restart of the LMA collector.
        score   => 0,
        require => Pcmk_colocation['log_collector-with-rabbitmq'],
      }
    }

    pacemaker::service { 'metric_collector':
      ensure           => present,
      prefix           => false,
      primitive_class  => 'ocf',
      primitive_type   => 'ocf-lma_collector',
      use_handler      => false,
      complex_type     => 'clone',
      complex_metadata => {
        # The resource can start at any time
        'interleave' => false,
      },
      metadata         => {
        # Make sure that Pacemaker tries to restart the resource if it fails
        # too many times
        'failure-timeout'     => '120s',
        'migration-threshold' => '3',
      },
      parameters       => {
        'service_name' => 'metric_collector',
        'config'       => '/etc/metric_collector',
        'log_file'     => '/var/log/metric_collector.log',
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
      require          => Lma_collector::Heka['metric_collector'],
    }
  }
}

class { 'lma_collector::logs::hdd_errors_counter':
  require => Class['lma_collector']
}

if hiera('lma::collector::elasticsearch::server', false) {
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
    server         => hiera('lma::collector::elasticsearch::server'),
    port           => hiera('lma::collector::elasticsearch::rest_port'),
    flush_interval => hiera('lma::collector::elasticsearch::flush_interval'),
    flush_count    => hiera('lma::collector::elasticsearch::flush_count'),
    require        => Class['lma_collector'],
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

if hiera('lma::collector::influxdb::server', false) {
  class { 'lma_collector::influxdb':
    server     => hiera('lma::collector::influxdb::server'),
    port       => hiera('lma::collector::influxdb::port'),
    database   => hiera('lma::collector::influxdb::database'),
    user       => hiera('lma::collector::influxdb::user'),
    password   => hiera('lma::collector::influxdb::password'),
    tag_fields => ['deployment_id', 'environment_label', 'tenant_id', 'user_id'],
    require    => Class['lma_collector'],
  }
}

if $is_rabbitmq and (hiera('lma::collector::elasticsearch::server', false) or hiera('lma::collector::influxdb::server', false)){
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

  if hiera('lma::collector::influxdb::server', false) {
    class { 'lma_collector::notifications::metrics': }
  }
}

class { 'fuel_lma_collector::tools': }
