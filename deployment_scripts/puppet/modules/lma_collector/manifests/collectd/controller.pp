class lma_collector::collectd::controller (
  $haproxy_socket,
  $service_user              = $lma_collector::params::openstack_user,
  $service_password          = $lma_collector::params::openstack_password,
  $service_tenant            = $lma_collector::params::openstack_tenant,
  $keystone_url              = $lma_collector::params::keystone_url,
  $nova_cpu_allocation_ratio = $lma_collector::params::nova_cpu_allocation_ratio,
  $rabbitmq_pid_file         = $lma_collector::params::rabbitmq_pid_file,
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
    'openstack_cinder' => {
      'Username' => $service_user,
      'Password' => $service_password,
      'Tenant' => $service_tenant,
      'KeystoneUrl' => $keystone_url,
      'Timeout' => $lma_collector::params::openstack_client_timeout,
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
  }

  if $haproxy_socket {
    $modules['haproxy'] = {
      'Socket' => $haproxy_socket
    }
  }

  $storage_options = hiera('storage', {})

  if $storage_options['volumes_ceph'] or $storage_options['images_ceph'] or $storage_options['objects_ceph'] or $storage_options['ephemeral_ceph']{
    $ceph_enabled = true
  } else {
    $ceph_enabled = false
  }

  if $ceph_enabled {
    $modules['ceph_pg_mon_status'] = {
      'Timeout' => '5',
      'Interval' => '30',
    }
    $modules['ceph_pool_osd'] = {
      'Timeout' => '5',
      'Interval' => '15',
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

  lma_collector::collectd::python_script { 'openstack_nova.py':
  }

  lma_collector::collectd::python_script { 'openstack_cinder.py':
  }

  lma_collector::collectd::python_script { 'openstack_glance.py':
  }

  lma_collector::collectd::python_script { 'openstack_keystone.py':
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
    lma_collector::collectd::python_script { 'base.py':
    }
    lma_collector::collectd::python_script { 'ceph_pool_osd.py':
    }
    lma_collector::collectd::python_script { 'ceph_pg_mon_status.py':
    }
  }
}
