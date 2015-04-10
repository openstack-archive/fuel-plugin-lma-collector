define lma_collector::collectd::dbi_services (
  $database         = undef,
  $hostname         = 'localhost',
  $username         = undef,
  $password         = undef,
  $dbname           = undef,
  $report_interval  = $lma_collector::params::worker_report_interval,
  $downtime_factor  = $lma_collector::params::worker_downtime_factor,
){
  include collectd::params
  include lma_collector::collectd::service
  $service = $title

  # A service is declared 'down' if heartbeat is not observered since
  # "downtime_factor * report_interval" seconds,
  # The "report_interval" must match the corresponding configuration of the service.

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
