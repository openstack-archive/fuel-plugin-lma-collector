class lma_collector::collectd::controller (
  $service_user = $lma_collector::params::openstack_user,
  $service_password = $lma_collector::params::openstack_password,
  $service_tenant = $lma_collector::params::openstack_tenant,
  $keystone_url = $lma_collector::params::keystone_url,
  $nova_cpu_allocation_ratio = $lma_collector::params::nova_cpu_allocation_ratio,
  $rabbitmq_pid_file = $lma_collector::params::rabbitmq_pid_file,
) {
  include lma_collector::params
  include collectd::params
  include lma_collector::collectd::service

  # We can't use the collectd::plugin::python type here because it doesn't
  # support the configuration of multiple Python plugins yet.
  # See https://github.com/pdxcat/puppet-module-collectd/issues/227
  $python_module_path = $lma_collector::params::python_module_path
  $modules = {
    'rabbitmq_info' => {
      'PidFile' => $rabbitmq_pid_file,
    },
    'check_openstack_api' => {
      'Username' => $service_user,
      'Password' => $service_password,
      'Tenant' => $service_tenant,
      'KeystoneUrl' => $keystone_url,
      'Timeout' => $lma_collector::params::openstack_client_timeout,
    },
    'hypervisor_stats' => {
      'Username' => $service_user,
      'Password' => $service_password,
      'Tenant' => $service_tenant,
      'KeystoneUrl' => $keystone_url,
      'Timeout' => $lma_collector::params::openstack_client_timeout,
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
  }

  file {"${collectd::params::plugin_conf_dir}/openstack.conf":
    owner   => 'root',
    group   => $collectd::params::root_group,
    mode    => '0644',
    content => template('lma_collector/collectd_python.conf.erb'),
    notify  => Class['lma_collector::collectd::service'],
  }

  file { "${python_module_path}/rabbitmq_info.py":
    owner   => 'root',
    group   => $collectd::params::root_group,
    mode    => '0644',
    source  => 'puppet:///modules/lma_collector/collectd/rabbitmq_info.py',
    notify  => Class['lma_collector::collectd::service'],
  }

  file { "${python_module_path}/check_openstack_api.py":
    owner   => 'root',
    group   => $collectd::params::root_group,
    mode    => '0644',
    source  => 'puppet:///modules/lma_collector/collectd/check_openstack_api.py',
    notify  => Class['lma_collector::collectd::service'],
  }

  file { "${python_module_path}/hypervisor_stats.py":
    owner   => 'root',
    group   => $collectd::params::root_group,
    mode    => '0644',
    source  => 'puppet:///modules/lma_collector/collectd/hypervisor_stats.py',
    notify  => Class['lma_collector::collectd::service'],
  }

  file { "${python_module_path}/openstack.py":
    ensure => present,
    source => 'puppet:///modules/lma_collector/collectd/openstack.py',
    notify  => Class['lma_collector::collectd::service'],
  }

  file { "${python_module_path}/openstack_nova.py":
    ensure => present,
    source => 'puppet:///modules/lma_toolchain/collectd/openstack_nova.py',
    notify  => Class['lma_collector::collectd::service'],
  }

  file { "${python_module_path}/openstack_cinder.py":
    ensure => present,
    source => 'puppet:///modules/lma_toolchain/collectd/openstack_cinder.py',
    notify  => Class['lma_collector::collectd::service'],
  }

  file { "${python_module_path}/openstack_glance.py":
    ensure => present,
    source => 'puppet:///modules/lma_toolchain/collectd/openstack_glance.py',
    notify  => Class['lma_collector::collectd::service'],
  }
}
