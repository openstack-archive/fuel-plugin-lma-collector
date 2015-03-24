# Class: lma_collector::mod_status
#
# We don't use apache::mod_status because it requires to include the apache
# base class. And by doing this we overwrite horizon configuration.

class lma_collector::mod_status {

  include apache::params
  include apache::service

  case $::osfamily {
    'redhat': {
      $status_conf = '/etc/httpd/conf.d/status.conf'
      $status_load = '/etc/httpd/conf.d/status.load'

      file { $status_load:
        source => 'puppet:///modules/lma_collector/apache/status.load'
      }

      file { $status_conf:
        source  => 'puppet:///modules/lma_collector/apache/status.conf',
        require => File[$status_load],
        notify  => Class['apache::service'],
      }
    }

    'debian': {
      $status_conf = '/etc/apache2/mods-enabled/status.conf'
      $status_load = '/etc/apache2/mods-enabled/status.load'

      file { $status_conf:
        ensure => link,
        target => '/etc/apache2/mods-available/status.conf',
      }

      file { $status_load:
        ensure  => link,
        target  => '/etc/apache2/mods-available/status.load',
        require => File[$status_conf],
        notify  => Class['apache::service'],
      }
    }

    default : {
      notify {"Cannot enable apache status module on ${::operatingsystem}": }
    }
  }
}
