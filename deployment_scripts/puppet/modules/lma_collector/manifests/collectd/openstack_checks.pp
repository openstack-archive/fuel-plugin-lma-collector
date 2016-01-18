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

class lma_collector::collectd::openstack_checks (
  $user,
  $password,
  $tenant,
  $keystone_url,
  $timeout = $lma_collector::params::openstack_client_timeout,
  $pacemaker_master_resource = undef,
) inherits lma_collector::params {

  include lma_collector::collectd::python_openstack_base

  $config = {
    'Username'    => "\"${user}\"",
    'Password'    => "\"${password}\"",
    'Tenant'      => "\"${tenant}\"",
    'KeystoneUrl' => "\"${keystone_url}\"",
    'Timeout'     => "\"${timeout}\"",
  }

  if $pacemaker_master_resource {
    $real_config = merge($config, {'DependsOnResource' => "\"${pacemaker_master_resource}\""})
  } else {
    $real_config = $config
  }

  lma_collector::collectd::python { 'check_openstack_api':
    config => $real_config,
  }

}
