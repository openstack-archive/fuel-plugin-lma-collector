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
define lma_collector::afd_nagios(
  $ensure = present,
  $hostname = $::hostname,
  $url       = undef,
  $user      = $lma_collector::params::nagios_user,
  $password  = $lma_collector::params::nagios_password,
  $field_name = 'node_role',
  $message_type = 'afd_node_metric',
  $roles = [],
  $cluster_roles = {},
  $alarms = {},
){
  include lma_collector::params
  include lma_collector::service

  if $url == undef {
    fail('url parameter is undef!')
  }
  if ! $hostname {
    fail('virtual_hostname is required!')
  }
  validate_string($url)
  validate_array($roles, $cluster_roles, $alarms)

  $services = get_afd_for_cluster(get_cluster_names($cluster_roles, $roles), $alarms)

  $config = hash(zip($services, $services))
  $_config = merge($config, {
                              'nagios_host' => $hostname,
                              'field_service_1' => $field_name,
                              'field_service_2' => 'source',
                              'prefix_service' => "${hostname}.",
                            })
  heka::encoder::sandbox { "nagios_afd_${title}":
    ensure     => $ensure,
    config_dir => $lma_collector::params::config_dir,
    filename   => "${lma_collector::params::plugins_dir}/encoders/status_nagios.lua",
    config     => $_config,
    notify     => Class['lma_collector::service'],
  }

  heka::output::http { "nagios_afd_${title}":
    ensure          => $ensure,
    config_dir      => $lma_collector::params::config_dir,
    url             => $url,
    message_matcher => "Type == 'heka.sandbox.${message_type}'",
    username        => $user,
    password        => $password,
    encoder         => "nagios_afd_${title}",
    timeout         => $lma_collector::params::nagios_timeout,
    headers         => {
      'Content-Type' => 'application/x-www-form-urlencoded'
    },
    require         => Heka::Encoder::Sandbox["nagios_afd_${title}"],
    notify          => Class['lma_collector::service'],
  }
}
