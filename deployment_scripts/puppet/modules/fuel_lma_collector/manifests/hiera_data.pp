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
define fuel_lma_collector::hiera_data (
  $content,
  $ensure = present,
) {
  $hiera_directory = '/etc/hiera/override'

  if $ensure == present {
    $parsed_yaml = parseyaml($content)

    if ! $parsed_yaml {
      # With stlib <= 4.9, parseyaml() will raise an exception if the generated
      # YAML is invalid so the Puppet parse will never get to the fail()
      # instruction.
      fail('Invalid YAML content!')
    }
    validate_hash($parsed_yaml)
    validate_hash($parsed_yaml['lma_collector'])
  }

  if !defined(Package['ruby-deep-merge']){
    package {'ruby-deep-merge':
      ensure  => 'installed',
    }
  }

  if !defined(File[$hiera_directory]){
    file { $hiera_directory:
      ensure  => directory,
    }
  }

  file { "${hiera_directory}/${name}.yaml":
    ensure  => $ensure,
    content => $content,
    require => File[$hiera_directory],
  }

  hiera_custom_source { "override/${name}":
    ensure => $ensure
  }
}
