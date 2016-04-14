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

notice('StackLight: lma_collector/cleanup_apt_config.pp')

include lma_collector::params

case $::osfamily {
    'Debian': {
        file { $::lma_collector::params::apt_config_file:
            ensure  => absent,
        }
    }
    default: {
        # Currently only Debian like distributions need specific configuration.
    }
}
