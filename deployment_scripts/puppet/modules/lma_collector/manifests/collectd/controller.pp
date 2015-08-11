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
class lma_collector::collectd::controller (
  $haproxy_socket            = undef,
  $haproxy_names_mapping     = $lma_collector::params::haproxy_names_mapping,
  $ceph_enabled              = undef,
  $service_user              = $lma_collector::params::openstack_user,
  $service_password          = $lma_collector::params::openstack_password,
  $service_tenant            = $lma_collector::params::openstack_tenant,
  $keystone_url              = $lma_collector::params::keystone_url,
  $nova_cpu_allocation_ratio = $lma_collector::params::nova_cpu_allocation_ratio,
  $memcached_host            = $lma_collector::params::memcached_host,
  $apache_host               = $lma_collector::params::apache_status_host,
  $pacemaker_resources       = undef,
  $pacemaker_master_resource = undef,
) inherits lma_collector::params {

  include collectd::params
  include lma_collector::collectd::service

  $openstack_configuration = {
    'Username'    => $service_user,
    'Password'    => $service_password,
    'Tenant'      => $service_tenant,
    'KeystoneUrl' => $keystone_url,
    'Timeout'     => $lma_collector::params::openstack_client_timeout,
  }
  if $pacemaker_master_resource {
    $openstack_configuration['DependsOnResource'] = $pacemaker_master_resource
  }

  # We can't use the collectd::plugin::python resource here because it doesn't
  # support the configuration of multiple Python plugins yet.
  # See https://github.com/pdxcat/puppet-module-collectd/issues/227
  $modules = {
    'rabbitmq_info'       => {
    },
    'check_openstack_api' => $openstack_configuration,
    'hypervisor_stats'    => merge(
      $openstack_configuration,
      {'CpuAllocationRatio' => $nova_cpu_allocation_ratio,}
    ),
    'openstack_nova'      => $openstack_configuration,
    'openstack_cinder'    => $openstack_configuration,
    'openstack_glance'    => $openstack_configuration,
    'openstack_keystone'  => $openstack_configuration,
    'openstack_neutron'   => $openstack_configuration,
  }

  if $pacemaker_resources {
    validate_array($pacemaker_resources)

    $modules['pacemaker_resource'] = {
      'Resource' => $pacemaker_resources,
    }

    if $pacemaker_master_resource {
      if ! member($pacemaker_resources, $pacemaker_master_resource) {
        fail("${pacemaker_master_resource} isn't a member of ${pacemaker_resources}")
      }
    }

    # Configure the filter that will notify other collectd plugins about the
    # state of the Pacemaker resources
    collectd::plugin { 'target_notification':
    }

    collectd::plugin { 'match_regex':
    }

    class { 'collectd::plugin::chain':
      chainname     => 'PostCache',
      defaulttarget => 'write',
      rules         => [
        {
          'match'   => {
            'type'    => 'regex',
            'matches' => {
              'Plugin'       => '^pacemaker_resource$',
              'TypeInstance' => "^${pacemaker_master_resource}$",
            },
          },
          'targets' => [
            {
              'type'       => 'notification',
              'attributes' => {
                'Message'  => '{\"resource\":\"%{type_instance}\",\"value\":%{ds:value}}',
                'Severity' => 'OKAY',
              },
            },
          ],
        },
      ],
    }
  }

  if $haproxy_socket {
    $modules['haproxy'] = {
      'Socket' => $haproxy_socket,
      'Mapping' => $haproxy_names_mapping,
      # Ignore internal proxy
      'ProxyIgnore' => 'Stats',
    }
  }

  if $ceph_enabled {
    $modules['ceph_pg_mon_status'] = {
      'Timeout' => '5',
    }
    $modules['ceph_pool_osd'] = {
      'Timeout' => '5',
    }
    $modules['ceph_osd_stats'] = {
      'Timeout' => '5',
    }
  }

  file {"${collectd::params::plugin_conf_dir}/openstack.conf":
    owner   => 'root',
    group   => $collectd::params::root_group,
    mode    => '0640',
    content => template('lma_collector/collectd_python.conf.erb'),
    notify  => Class['lma_collector::collectd::service'],
  }

  lma_collector::collectd::python_script { 'base.py':
  }

  lma_collector::collectd::python_script { 'rabbitmq_info.py':
  }

  lma_collector::collectd::python_script { 'check_openstack_api.py':
  }

  lma_collector::collectd::python_script { 'hypervisor_stats.py':
  }

  lma_collector::collectd::python_script { 'openstack.py':
  }

  lma_collector::collectd::python_script { 'openstack_nova.py':
  }

  lma_collector::collectd::python_script { 'openstack_cinder.py':
  }

  lma_collector::collectd::python_script { 'openstack_glance.py':
  }

  lma_collector::collectd::python_script { 'openstack_keystone.py':
  }

  lma_collector::collectd::python_script { 'openstack_neutron.py':
  }

  if $haproxy_socket {
    lma_collector::collectd::python_script { 'haproxy.py':
    }
  }

  if $pacemaker_resources {
    lma_collector::collectd::python_script { 'pacemaker_resource.py':
    }
  }

  class { 'collectd::plugin::memcached':
    host => $memcached_host,
  }

  class { 'collectd::plugin::apache':
    instances => {
      'localhost' => {
        'url' => "http://${apache_host}/server-status?auto"
      },
    }
  }

  if $ceph_enabled {
    lma_collector::collectd::python_script { 'ceph_pool_osd.py':
    }
    lma_collector::collectd::python_script { 'ceph_pg_mon_status.py':
    }
    lma_collector::collectd::python_script { 'ceph_osd_stats.py':
    }
  }
}
