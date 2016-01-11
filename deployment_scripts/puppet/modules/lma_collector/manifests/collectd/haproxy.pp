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

class lma_collector::collectd::haproxy (
  $socket,
  $proxy_ignore = [],
  $proxy_names = {},
) {

  include lma_collector::params

  validate_array($proxy_ignore)
  validate_hash($proxy_names)

  lma_collector::collectd::python { 'haproxy':
    config => {
      'Socket'      => $socket,
      'Mapping'     => $proxy_names,
      'ProxyIgnore' => $proxy_ignore,
    },
  }
}
