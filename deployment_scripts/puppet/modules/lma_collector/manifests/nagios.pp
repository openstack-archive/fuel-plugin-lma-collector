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
define lma_collector::nagios (
  $ensure = present,
  $openstack_deployment_name = '',
  $url       = undef,
  $user      = $lma_collector::params::nagios_user,
  $password  = $lma_collector::params::nagios_password,
  $clusters = [],
  $message_type = undef,
  $virtual_hostname = undef,
) {
  include lma_collector::service
  include lma_collector::params

  if $url == undef {
    fail('url parameter is undef!')
  }
  if empty($clusters) {
    fail('clusters is empty!')
  }
  if ! $message_type {
    fail('message_type is undef!')
  }
  if ! $virtual_hostname {
    fail('virtual_hostname is required!')
  }
  validate_string($url)

  $suffix = $lma_collector::params::nagios_cluster_status_suffix

  # This must be identical logic than in lma-infra-alerting-plugin

  $_nagios_host = "${virtual_hostname}-env${openstack_deployment_name}"
  $config = hash(zip($clusters, suffix($clusters, $suffix)))
  $_config = merge($config, {'nagios_host' => $_nagios_host})

  heka::encoder::sandbox { "nagios_${title}":
    ensure     => $ensure,
    config_dir => $lma_collector::params::config_dir,
    filename   => "${lma_collector::params::plugins_dir}/encoders/status_nagios.lua",
    config     => $_config,
    notify     => Class['lma_collector::service'],
  }


  heka::output::http { "nagios_${title}":
    ensure          => $ensure,
    config_dir      => $lma_collector::params::config_dir,
    url             => $url,
    message_matcher => "Type == 'heka.sandbox.${message_type}'",
    username        => $user,
    password        => $password,
    encoder         => "nagios_${title}",
    timeout         => $lma_collector::params::nagios_timeout,
    headers         => {
      'Content-Type' => 'application/x-www-form-urlencoded'
    },
    require         => Heka::Encoder::Sandbox["nagios_${title}"],
    notify          => Class['lma_collector::service'],
  }
}
