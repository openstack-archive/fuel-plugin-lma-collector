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

define lma_collector::collectd::openstack (
  $user,
  $password,
  $tenant,
  $keystone_url,
  $timeout = undef,
  $max_retries = undef,
  $pacemaker_master_resource = undef,
) {

  include lma_collector::params
  include lma_collector::collectd::python_openstack_base

  $service = $title

  $supported_services = ['nova', 'cinder', 'glance', 'keystone', 'neutron']
  if ! member($supported_services, $service) {
    fail("service '${service}' is not supported")
  }

  $real_timeout = $timeout ? {
    undef   => $lma_collector::params::openstack_client_objects_timeout,
    default => $timeout,
  }

  $real_max_retries = $max_retries ? {
    undef   => $lma_collector::params::openstack_client_objects_max_retries,
    default => $max_retries,
  }

  validate_integer($real_timeout)
  validate_integer($real_max_retries)

  $config = {
    'Username'    => "\"${user}\"",
    'Password'    => "\"${password}\"",
    'Tenant'      => "\"${tenant}\"",
    'KeystoneUrl' => "\"${keystone_url}\"",
    'Timeout'     => "\"${real_timeout}\"",
    'MaxRetries'  => "\"${real_max_retries}\"",
  }

  if $pacemaker_master_resource {
    $real_config = merge($config, {'DependsOnResource' => "\"${pacemaker_master_resource}\""})
  } else {
    $real_config = $config
  }

  lma_collector::collectd::python { "openstack_${title}":
    config => $real_config,
  }

}
