#    Copyright 2016 Mirantis, Inc.
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

class fuel_lma_collector::tools {

  file { '/usr/local/bin/lma_diagnostics':
    ensure  => present,
    source  => 'puppet:///modules/fuel_lma_collector/diagnostics.sh',
    mode    => '0755',
    owner   => 'root',
    group   => 'root',
    require => Package['sysstat'],
  }
  package {'sysstat':
    ensure => installed,
  }
}
