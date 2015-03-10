class lma_collector::collectd::mysql (
  $username = $lma_collector::params::mysql_username,
  $password = $lma_collector::params::mysql_password,
) inherits lma_collector::params {
  include lma_collector::collectd::service

  collectd::plugin::mysql::database { 'openstack':
    host     => 'localhost',
    username => $username,
    password => $password,
    notify   => Class['lma_collector::collectd::service'],
  }
}
