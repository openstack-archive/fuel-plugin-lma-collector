define lma_collector::collectd::dbi_services (
  $database         = undef,
  $hostname         = 'localhost',
  $username         = undef,
  $password         = undef,
  $dbname           = undef,
  $report_interval  = 60,
  $downtime_factor  = 2,
){
  include collectd::params
  include lma_collector::collectd::service
  $service = $title

  $downtime = $report_interval * $downtime_factor

  if $service == 'nova' or $service == 'cinder' {
    $type = 'services'
  }elsif $service == 'neutron' {
    $type = 'agents'
  }else{
    fail("${service} not supported")
  }

  $plugin_conf_dir = $collectd::params::plugin_conf_dir

  file { "${plugin_conf_dir}/dbi_${service}_${type}.conf":
    owner   => 'root',
    group   => $collectd::params::root_group,
    mode    => '0640',
    content => template('lma_collector/collectd_dbi_services.conf.erb'),
    notify  => Class['lma_collector::collectd::service'],
  }
}
