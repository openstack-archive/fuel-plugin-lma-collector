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
define lma_collector::gse_nagios (
  $ensure = present,
  $openstack_deployment_name = '',
  $url       = undef,
  $user      = $lma_collector::params::nagios_user,
  $password  = $lma_collector::params::nagios_password,
  $service_template  = '%{cluster_name}',
  $message_type = undef,
  $virtual_hostname = undef,
) {
  include lma_collector::params
  include lma_collector::service

  $lua_modules_dir = $lma_collector::params::lua_modules_dir

  if $url == undef {
    fail('url parameter is undef!')
  }
  if ! $message_type {
    fail('message_type is undef!')
  }
  if ! $virtual_hostname {
    fail('virtual_hostname is required!')
  }
  validate_string($url)

  # This must be identical logic than in lma-infra-alerting-plugin
  $_nagios_host = "${virtual_hostname}-env${openstack_deployment_name}"

  $config = {'nagios_host' => $_nagios_host, 'service_template' => $service_template}
  heka::encoder::sandbox { "nagios_gse_${title}":
    ensure           => $ensure,
    config_dir       => $lma_collector::params::config_dir,
    filename         => "${lma_collector::params::plugins_dir}/encoders/status_nagios.lua",
    config           => $config,
    module_directory => $lua_modules_dir,
    notify           => Class['lma_collector::service'],
  }

  heka::output::http { "nagios_gse_${title}":
    ensure          => $ensure,
    config_dir      => $lma_collector::params::config_dir,
    url             => $url,
    message_matcher => "Type == 'heka.sandbox.${message_type}'",
    username        => $user,
    password        => $password,
    encoder         => "nagios_gse_${title}",
    timeout         => $lma_collector::params::nagios_timeout,
    headers         => {
      'Content-Type' => 'application/x-www-form-urlencoded'
    },
    use_buffering   => $lma_collector::params::buffering_enabled,
    max_buffer_size => $lma_collector::params::buffering_max_buffer_tiny_size,
    max_file_size   => $lma_collector::params::buffering_max_file_tiny_size,
    require         => Heka::Encoder::Sandbox["nagios_gse_${title}"],
    notify          => Class['lma_collector::service'],
  }
}
