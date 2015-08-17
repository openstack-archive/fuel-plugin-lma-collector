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
# Class: lma_collector::collectd::service
#
# Manages the collectd daemon
#
# Sample Usage:
#
# sometype { 'foo':
#   notify => Class['lma_collector::collectd::service'],
# }
#
#
class lma_collector::collectd::service (
  $service_enable = true,
  $service_ensure = 'running',
  $service_manage = true,
) {
  include collectd::params

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

  if $service_manage {
    service { 'collectd':
      ensure => $_service_ensure,
      enable => $service_enable,
    }
  }
}

