define lma_collector::collectd::dbi_mysql_status (
  $database         = undef,
  $hostname         = 'localhost',
  $username         = undef,
  $password         = undef,
  $dbname           = undef,
){
  include collectd::params
  include lma_collector::collectd::service

  $plugin_conf_dir = $collectd::params::plugin_conf_dir
  file { "${plugin_conf_dir}/dbi_mysql_status.conf":
    owner   => 'root',
    group   => $collectd::params::root_group,
    mode    => '0640',
    content => template('lma_collector/collectd_dbi_mysql_status.conf.erb'),
    notify  => Class['lma_collector::collectd::service'],
  }
}

