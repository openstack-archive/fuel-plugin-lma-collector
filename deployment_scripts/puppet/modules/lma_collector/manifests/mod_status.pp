# Class: lma_collector::mod_status
class lma_collector::mod_status {

  case $::operatingsystem {
    centos, redhat: {
      $status_conf = '/etc/httpd/conf.d/status.conf'
      $status_load = '/etc/httpd/conf.d/status.load'

      file { $status_load:
        source => 'puppet:///modules/lma_collector/apache/status.load'
      }

      file { $status_conf:
        source  => 'puppet:///modules/lma_collector/apache/status.conf',
        require => File[$status_load],
        notify  => Service['httpd'],
      }

      service { 'httpd':
        ensure => 'running',
      }
    }

    debian, ubuntu : {
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
        notify  => Service['apache2'],
      }

      service {'apache2':
        ensure => 'running',
      }
    }

    default : {
      notify {"Cannot enable apache status module on ${::operatingsystem}": }
    }
  }
}
