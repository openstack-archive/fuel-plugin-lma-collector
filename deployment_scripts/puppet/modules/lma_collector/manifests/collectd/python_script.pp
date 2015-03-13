define lma_collector::collectd::python_script {
  include collectd::params
  include lma_collector::params
  include lma_collector::collectd::service

  $python_module_path = $lma_collector::params::python_module_path

  file { "${python_module_path}/${title}":
    owner   => 'root',
    group   => $collectd::params::root_group,
    mode    => '0644',
    source  => "puppet:///modules/lma_collector/collectd/${title}",
    notify  => Class['lma_collector::collectd::service'],
  }
}
