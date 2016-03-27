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
# Class: lma_collector::service:metric
#
# Manages the Metric collector daemon
#
# Sample Usage:
#
# sometype { 'foo':
#   notify => Class['lma_collector::service::metric'],
# }
#
#
class lma_collector::service::metric {
  include lma_collector::params

  service { $::lma_collector::params::metric_service_name:
    ensure => 'running',
    enable => true,
  }
}
