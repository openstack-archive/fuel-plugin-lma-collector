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

class lma_collector::collectd::haproxy (
  $socket,
) {

  include lma_collector::params

  lma_collector::collectd::python_script { 'haproxy':
    config => {
      'Socket'      => $socket,
      'Mapping'     => $lma_collector::params::haproxy_names_mapping,
      # Ignore internal stats ('Stats' for 6.1, 'stats' for 7.0) and lma proxies
      'ProxyIgnore' => ['Stats', 'stats', 'lma'],
    },
  }
}
