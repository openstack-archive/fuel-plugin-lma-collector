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

class lma_collector::collectd::rabbitmq (
  $username,
  $password,
  $host = undef,
  $port = undef,
) {

  if $host {
    $host_config = {
      'Host' => "\"${host}\"",
    }
  } else {
    $host_config = {}
  }

  if $port {
    validate_integer($port)
    $port_config = {
      'Port' => "\"${port}\"",
    }
  } else {
    $port_config = {}
  }

  $config = {
    'Username' => "\"${username}\"",
    'Password' => "\"${password}\"",
  }

  lma_collector::collectd::python { 'rabbitmq_info':
    config => merge($config, $host_config, $port_config)
  }
}
