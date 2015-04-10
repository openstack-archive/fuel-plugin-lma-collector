class lma_collector::collectd::dbi (
  $interval = '10'
){
  include collectd::params
  include lma_collector::params
  include lma_collector::collectd::service

  package { $lma_collector::params::collectd_dbi_package:
    ensure   => present,
    name     => $lma_collector::params::collectd_dbi_package,
  } ->
  collectd::plugin { 'dbi':
    interval => $interval,
  }
}
