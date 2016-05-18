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
# Class: fuel_lma_collector::mod_status
#
# We don't use apache::mod_status because it requires to include the apache
# base class. And by doing this we would overwrite the Horizon configuration.

class fuel_lma_collector::mod_status (
  $allow_from = $fuel_lma_collector::params::apache_allow_from,
) inherits fuel_lma_collector::params {

  include apache::params
  include apache::service

  validate_array($allow_from)

  $lib_path    = $::apache::params::lib_path
  $status_conf = "${::apache::params::mod_dir}/status.conf"
  $status_load = "${::apache::params::mod_dir}/status.load"

  if $::osfamily == 'debian' {
    $status_conf_link = "${::apache::params::mod_enable_dir}/status.conf"
    $status_load_link = "${::apache::params::mod_enable_dir}/status.load"

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

  # This template uses $allow_from and $lib_path
  file { $status_conf:
    ensure  => file,
    content => template('fuel_lma_collector/apache/status.conf.erb'),
    require => File[$status_load],
    notify  => Class['apache::service'],
  }

  file { $status_load:
    ensure  => file,
    content => template('fuel_lma_collector/apache/status.load.erb'),
  }

}
