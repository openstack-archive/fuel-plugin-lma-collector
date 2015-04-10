class lma_collector::collectd::dbi_services (
  $service   = undef,
  $database  = undef,
  $hostname  = 'localhost',
  $username  = undef,
  $password  = undef,
  $dbname    = undef,
){
  include collectd::params
  include lma_collector::collectd::service

  $plugin_conf_dir = $collectd::params::plugin_conf_dir

  file { "${plugin_conf_dir}/dbi_${service}_services.conf":
    owner   => 'root',
    group   => $collectd::params::root_group,
    mode    => '0644',
    content => template('lma_collector/collectd_dbi_services.conf.erb'),
    notify  => Class['lma_collector::collectd::service'],
  }
}
