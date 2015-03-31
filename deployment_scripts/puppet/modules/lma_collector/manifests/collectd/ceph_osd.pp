class lma_collector::collectd::ceph_osd
{
  include lma_collector::params
  include collectd::params
  include lma_collector::collectd::service

  $python_module_path = $lma_collector::params::python_module_path

  $modules = {
    'ceph_osd_perf' => {
      'AdminSocket'   => '/var/run/ceph/ceph-*.asok',
    },
  }
  file {"${collectd::params::plugin_conf_dir}/ceph-osd.conf":
    owner   => 'root',
    group   => $collectd::params::root_group,
    mode    => '0644',
    content => template('lma_collector/collectd_python.conf.erb'),
    notify  => Class['lma_collector::collectd::service'],
  }

  lma_collector::collectd::python_script { 'base.py':
  }

  lma_collector::collectd::python_script { 'ceph_osd_perf.py':
  }

}
