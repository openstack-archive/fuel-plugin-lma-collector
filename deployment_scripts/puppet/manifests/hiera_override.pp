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

$plugin_data = hiera('lma_collector', undef)

if ($plugin_data) {
  $storage_options = hiera_hash('storage', {})
  $tls_enabled = hiera('public_ssl', false)
  $ceilometer = hiera_hash('ceilometer', {})
  $ceilometer_enabled = pick($ceilometer['enabled'], false)

  $elasticsearch_mode = $plugin_data['elasticsearch_mode']
  if $elasticsearch_mode != 'disabled' {
      $elasticsearch_enabled = true
  } else {
      $elasticsearch_enabled = false
  }

  lma_collector::hiera_data { 'gse_filters':
    content => template('lma_collector/gse_filters.yaml.erb')
  }

  lma_collector::hiera_data { 'alarming':
    content => template('lma_collector/alarming.yaml.erb')
  }
}
