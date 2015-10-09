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
  $cluster_nodes = [],
  $cluster_services = [],
) inherits lma_collector::params {
  include lma_collector::service

  if $url == undef {
    fail('url parameter is undef!')
  }
  validate_string($url)

  $suffix = $lma_collector::params::nagios_cluster_status_suffix

  # This must be identical logic than in lma-infra-alerting-plugin

  $prefix = $lma_collector::params::nagios_global_cluster_status_prefix
  $nagios_host_services = $lma_collector::params::nagios_hostname_for_cluster_global
  $_nagios_host_for_services = "${nagios_host_services}-env${openstack_deployment_name}"
  $config_for_services = hash(zip($cluster_services, suffix(prefix($cluster_services, $prefix), $suffix)))
  $_config_for_services = merge($config_for_services, {'nagios_host' => $_nagios_host_for_services})

  $nagios_host_nodes = $lma_collector::params::nagios_hostname_for_cluster_nodes
  $_nagios_host_for_nodes = "${nagios_host_nodes}-env${openstack_deployment_name}"
  $config_for_nodes = hash(zip($cluster_nodes, suffix($cluster_nodes, $suffix)))
  $_config_for_nodes = merge($config_for_nodes, {'nagios_host' => $_nagios_host_for_nodes})

  heka::encoder::sandbox { 'nagios_cluster_services':
    config_dir => $lma_collector::params::config_dir,
    filename   => "${lma_collector::params::plugins_dir}/encoders/status_nagios.lua",
    config     => $_config_for_services,
    notify     => Class['lma_collector::service'],
  }

  heka::encoder::sandbox { 'nagios_cluster_nodes':
    config_dir => $lma_collector::params::config_dir,
    filename   => "${lma_collector::params::plugins_dir}/encoders/status_nagios.lua",
    config     => $_config_for_nodes,
    notify     => Class['lma_collector::service'],
  }


  heka::output::http { 'nagios_cluster_services':
    config_dir      => $lma_collector::params::config_dir,
    url             => $url,
    message_matcher => 'Type == \'heka.sandbox.gse_cluster_metric\'',
    username        => $user,
    password        => $password,
    encoder         => 'nagios_cluster_services',
    timeout         => $lma_collector::params::nagios_timeout,
    headers         => {
      'Content-Type' => 'application/x-www-form-urlencoded'
    },
    require         => Heka::Encoder::Sandbox['nagios_cluster_services'],
    notify          => Class['lma_collector::service'],
  }

  heka::output::http { 'nagios_cluster_nodes':
    config_dir      => $lma_collector::params::config_dir,
    url             => $url,
    message_matcher => 'Type == \'heka.sandbox.gse_node_cluster_metric\'',
    username        => $user,
    password        => $password,
    encoder         => 'nagios_cluster_nodes',
    timeout         => $lma_collector::params::nagios_timeout,
    headers         => {
      'Content-Type' => 'application/x-www-form-urlencoded'
    },
    require         => Heka::Encoder::Sandbox['nagios_cluster_nodes'],
    notify          => Class['lma_collector::service'],
  }
}
