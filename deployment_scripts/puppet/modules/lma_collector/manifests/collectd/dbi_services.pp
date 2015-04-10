define lma_collector::collectd::dbi_services (
  $database         = undef,
  $hostname         = 'localhost',
  $username         = undef,
  $password         = undef,
  $dbname           = undef,
  $downtime         = '60',
){
  include collectd::params
  include lma_collector::params
  include lma_collector::collectd::service
  $service = $title

  $plugin_conf_dir = $collectd::params::plugin_conf_dir

  package { $lma_collector::params::collectd_dbi_package:
    ensure   => present,
    name     => $lma_collector::params::collectd_dbi_package,
    before   => File["${plugin_conf_dir}/dbi_${service}_services.conf"],
  }

  file { "${plugin_conf_dir}/dbi_${service}_services.conf":
    owner   => 'root',
    group   => $collectd::params::root_group,
    mode    => '0644',
    content => template('lma_collector/collectd_dbi_services.conf.erb'),
    notify  => Class['lma_collector::collectd::service'],
  }
}
