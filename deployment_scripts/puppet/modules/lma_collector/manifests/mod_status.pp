#    Copyright 2015 Mirantis, Inc.
#
#    Licensed under the Apache License, Version 2.0 (the "License"); you may
#    not use this file except in compliance with the License. You may obtain
#    a copy of the License at
#
#         http://www.apache.org/licenses/LICENSE-2.0
#
#    Unless required by applicable law or agreed to in writing, software
#    distributed under the License is distributed on an "AS IS" BASIS, WITHOUT
#    WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. See the
#    License for the specific language governing permissions and limitations
#    under the License.
#
# Class: lma_collector::mod_status
#
# We don't use apache::mod_status because it requires to include the apache
# base class. And by doing this we overwrite horizon configuration.

class lma_collector::mod_status (
  $allow_from = ['127.0.0.1'],
) {

  include apache::params
  include apache::service

  validate_array($allow_from)

  case $::osfamily {
    'redhat': {
      $lib_path    = 'modules/'
      $status_conf = '/etc/httpd/conf.d/status.conf'
      $status_load = '/etc/httpd/conf.d/status.load'
    }

    'debian': {
      $lib_path    = '/usr/lib/apache2/modules/'
      $status_conf = '/etc/apache2/mods-available/status.conf'
      $status_load = '/etc/apache2/mods-available/status.load'
      $status_conf_link = '/etc/apache2/mods-enabled/status.conf'
      $status_load_link = '/etc/apache2/mods-enabled/status.load'

      file { $status_conf_link:
        ensure  => link,
        target  => $status_conf,
        require => File[$status_conf],
      }

      file { $status_load_link:
        ensure  => link,
        target  => $status_load,
        require => File[$status_load],
        notify  => Class['apache::service'],
      }
    }

    default : {
      notify {"Cannot enable apache status module on ${::operatingsystem}": }
    }
  }

  # Template uses $allow_from, $lib_path
  file { $status_conf:
    ensure  => file,
    content => template('lma_collector/apache/status.conf.erb'),
    require => File[$status_load],
    notify  => Class['apache::service'],
  }

  file { $status_load:
    ensure  => file,
    content => template('lma_collector/apache/status.load.erb'),
  }

}
