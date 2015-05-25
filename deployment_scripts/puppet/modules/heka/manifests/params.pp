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
class heka::params {
  $package_name = 'heka'
  $service_name = 'hekad'
  $user = 'heka'
  $run_as_root = false
  $additional_groups = []

  $hostname = undef
  $maxprocs = $::processorcount
  $max_message_size = 65536
  $dashboard_address = undef
  $dashboard_port = '4352'
  $internal_statistics = false

  $config_dir = "/etc/${service_name}"
  $share_dir = '/usr/share/heka'
  $lua_modules_dir = '/usr/share/heka/lua_modules'

  # required to read the log files
  case $::osfamily {
    'Debian': {
      $groups = ['syslog', 'adm']
    }
    'RedHat': {
      $groups = ['adm']
    }
    default: {
      fail("${::osfamily} not supported")
    }
  }
}
