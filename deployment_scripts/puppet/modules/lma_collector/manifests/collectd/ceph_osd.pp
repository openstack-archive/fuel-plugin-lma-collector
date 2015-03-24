class lma_collector::collectd::ceph_osd (
  $osd_socket = $lma_collector::params::osd_socket,
) inherits lma_collector::params {
  include collectd::params
  include lma_collector::collectd::service

  $modules = {
    'ceph_osd' => {
      'Socket' => $osd_socket,
    },
  }

  lma_collector::collectd::python_script { 'base.py':
  }

  lma_collector::collectd::python_script { 'ceph_osd_perf.py':
  }

}
