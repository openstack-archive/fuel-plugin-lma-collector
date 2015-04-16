class lma_collector::collectd::dbi {
  include lma_collector::params
  include lma_collector::collectd::service

  if $::osfamily == 'RedHat' {
    package { 'collectd-dbi':
      ensure => present,
    }
  }

  package { $lma_collector::params::collectd_dbi_package:
    ensure => present,
  }

  collectd::plugin { 'dbi':
    require => Package[$lma_collector::params::collectd_dbi_package],
  }
}
