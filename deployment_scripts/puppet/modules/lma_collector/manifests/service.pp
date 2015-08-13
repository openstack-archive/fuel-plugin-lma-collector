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
# Class: lma_collector::service
#
# Manages the LMA collector daemon
#
# Sample Usage:
#
# sometype { 'foo':
#   notify => Class['lma_collector::service'],
# }
#
#
class lma_collector::service (
  $service_name = $::lma_collector::params::service_name,
  $service_enable = true,
  $service_ensure = 'running',
  $service_manage = true,
  $provider       = undef,
) {
  # The base class must be included first because parameter defaults depend on it
  if ! defined(Class['lma_collector::params']) {
    fail('You must include the lma_collector::params class before using lma_collector::service')
  }

  validate_bool($service_enable)
  validate_bool($service_manage)

  case $service_ensure {
    true, false, 'running', 'stopped': {
      $_service_ensure = $service_ensure
    }
    default: {
      $_service_ensure = undef
    }
  }

  if member(split($::pacemaker_resources, ','), $service_name) {
    $real_provider = 'pacemaker'
  } else {
    $real_provider = $provider
  }

  if $service_manage {
    if $real_provider {
      service { 'lma_collector':
        ensure   => $_service_ensure,
        name     => $service_name,
        enable   => $service_enable,
        provider => $real_provider,
      }
    } else {
      service { 'lma_collector':
        ensure => $_service_ensure,
        name   => $service_name,
        enable => $service_enable,
      }
    }
  }
}
