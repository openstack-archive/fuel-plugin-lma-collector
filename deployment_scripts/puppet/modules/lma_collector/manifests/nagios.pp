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
class lma_collector::nagios (
  $openstack_deployment_name = '',
  $url       = undef,
  $user      = $lma_collector::params::nagios_user,
  $password  = $lma_collector::params::nagios_password,
  $ensure = present,
) inherits lma_collector::params {
  include lma_collector::service

  if $url == undef {
    fail('url parameter is undef!')
  }
  validate_string($url)

  # This must be identical logic than in lma-infra-alerting-plugin
  $nagios_host = $lma_collector::params::nagios_hostname_service_status
  $_nagios_host = "${nagios_host}-env${openstack_deployment_name}"
  $config = $lma_collector::params::nagios_event_status_name_to_service_name_map
  $config['nagios_host'] = $_nagios_host

  heka::encoder::sandbox { 'nagios':
    config_dir => $lma_collector::params::config_dir,
    filename   => "${lma_collector::params::plugins_dir}/encoders/status_nagios.lua",
    config     => $config,
    notify     => Class['lma_collector::service'],
  }

  heka::output::http { 'nagios':
    config_dir      => $lma_collector::params::config_dir,
    url             => $url,
    message_matcher => 'Type == \'heka.sandbox.status\'',
    username        => $user,
    password        => $password,
    encoder         => 'nagios',
    timeout         => $lma_collector::params::nagios_timeout,
    headers         => {
      'Content-Type' => 'application/x-www-form-urlencoded'
    },
    require         => Heka::Encoder::Sandbox['nagios'],
    notify          => Class['lma_collector::service'],
  }
}
