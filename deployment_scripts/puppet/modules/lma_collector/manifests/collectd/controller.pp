class lma_collector::collectd::controller (
  $haproxy_socket            = undef,
  $ceph_enabled              = undef,
  $service_user              = $lma_collector::params::openstack_user,
  $service_password          = $lma_collector::params::openstack_password,
  $service_tenant            = $lma_collector::params::openstack_tenant,
  $keystone_url              = $lma_collector::params::keystone_url,
  $nova_cpu_allocation_ratio = $lma_collector::params::nova_cpu_allocation_ratio,
  $rabbitmq_pid_file         = $lma_collector::params::rabbitmq_pid_file,
  $nova_db_hostname          = 'localhost',
  $nova_db_name              = 'nova',
  $nova_db_user              = 'nova',
  $nova_db_password          = false,
  $cinder_db_hostname        = 'localhost',
  $cinder_db_name            = 'cinder',
  $cinder_db_user            = 'cinder',
  $cinder_db_password        = false,
  $neutron_db_hostname        = 'localhost',
  $neutron_db_name            = 'neutron',
  $neutron_db_user            = 'neutron',
  $neutron_db_password        = false,
) inherits lma_collector::params {
  include collectd::params
  include lma_collector::collectd::service

  # We can't use the collectd::plugin::python type here because it doesn't
  # support the configuration of multiple Python plugins yet.
  # See https://github.com/pdxcat/puppet-module-collectd/issues/227
  $modules = {
    'rabbitmq_info'       => {
      'PidFile' => $rabbitmq_pid_file,
    },
    'check_openstack_api' => {
      'Username'    => $service_user,
      'Password'    => $service_password,
      'Tenant'      => $service_tenant,
      'KeystoneUrl' => $keystone_url,
      'Timeout'     => $lma_collector::params::openstack_client_timeout,
    },
    'hypervisor_stats'    => {
      'Username'           => $service_user,
      'Password'           => $service_password,
      'Tenant'             => $service_tenant,
      'KeystoneUrl'        => $keystone_url,
      'Timeout'            => $lma_collector::params::openstack_client_timeout,
      'CpuAllocationRatio' => $nova_cpu_allocation_ratio,
    },
    'openstack_nova' => {
      'Username' => $service_user,
      'Password' => $service_password,
      'Tenant' => $service_tenant,
      'KeystoneUrl' => $keystone_url,
      'Timeout' => $lma_collector::params::openstack_client_timeout,
    },

    'openstack_nova_services' => {
      'Connection' => "mysql://${nova_db_user}:${nova_db_password}@$nova_db_hostname/${nova_db_name}",
    },

    'openstack_cinder' => {
      'Username' => $service_user,
      'Password' => $service_password,
      'Tenant' => $service_tenant,
      'KeystoneUrl' => $keystone_url,
      'Timeout' => $lma_collector::params::openstack_client_timeout,
    },
    'openstack_cinder_services' => {
      'Connection' => "mysql://${cinder_db_user}:${cinder_db_password}@$cinder_db_hostname/${cinder_db_name}",
    },
    'openstack_glance' => {
      'Username' => $service_user,
      'Password' => $service_password,
      'Tenant' => $service_tenant,
      'KeystoneUrl' => $keystone_url,
      'Timeout' => $lma_collector::params::openstack_client_timeout,
    },
    'openstack_keystone' => {
      'Username' => $service_user,
      'Password' => $service_password,
      'Tenant' => $service_tenant,
      'KeystoneUrl' => $keystone_url,
      'Timeout' => $lma_collector::params::openstack_client_timeout,
    },
    'openstack_neutron' => {
      'Username' => $service_user,
      'Password' => $service_password,
      'Tenant' => $service_tenant,
      'KeystoneUrl' => $keystone_url,
      'Timeout' => $lma_collector::params::openstack_client_timeout,
    },
    'openstack_neutron_services' => {
      'Connection' => "mysql://${neutron_db_user}:${neutron_db_password}@$neutron_db_hostname/${neutron_db_name}",
    },
  }

  if $haproxy_socket {
    $modules['haproxy'] = {
      'Socket' => $haproxy_socket
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
    mode    => '0644',
    content => template('lma_collector/collectd_python.conf.erb'),
    notify  => Class['lma_collector::collectd::service'],
  }

  lma_collector::collectd::python_script { 'rabbitmq_info.py':
  }

  lma_collector::collectd::python_script { 'check_openstack_api.py':
  }

  lma_collector::collectd::python_script { 'hypervisor_stats.py':
  }

  lma_collector::collectd::python_script { 'openstack.py':
  }

  lma_collector::collectd::python_script { 'base.py':
  }

  lma_collector::collectd::python_script { 'dbbase.py':
  }

  lma_collector::collectd::python_script { 'openstack_nova.py':
  }

  lma_collector::collectd::python_script { 'openstack_nova_services.py':
  }

  lma_collector::collectd::python_script { 'openstack_cinder_services.py':
  }

  lma_collector::collectd::python_script { 'openstack_neutron_services.py':
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

  class { 'collectd::plugin::memcached':
  }

  class { 'collectd::plugin::apache':
    instances => {
      'localhost' => {
        'url' => 'http://localhost/server-status?auto'
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
