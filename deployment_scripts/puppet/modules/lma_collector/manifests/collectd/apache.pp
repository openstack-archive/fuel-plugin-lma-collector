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
#

class lma_collector::collectd::apache (
  $host = $lma_collector::params::apache_status_host,
  $port = $lma_collector::params::apache_status_port,
) inherits lma_collector::params {

  $apache_url = "http://${host}:${port}/server-status?auto"

  class { 'collectd::plugin::apache':
    instances => {
      'localhost' => {
        'url' => $apache_url,
      },
    }
  }

  lma_collector::collectd::python {'collectd_apache_check':
    config => {
      'Url' => "\"${apache_url}\"",
    },
  }
}
