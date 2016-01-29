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
class lma_collector::collectd::mysql (
  $host = $lma_collector::params::mysql_host,
  $port = $lma_collector::params::mysql_port,
  $username = $lma_collector::params::mysql_username,
  $password = $lma_collector::params::mysql_password,
) inherits lma_collector::params {

  # Previously the collectd::plugin::mysql::database resource title was "nova",
  # which did not make sense as the monitoring of MySQL is not at all related
  # to Nova.  So we use a different resource title and make sure that the file
  # associated with the "nova" resource is absent.

  collectd::plugin::mysql::database { 'nova':
    ensure => absent,
  }

  collectd::plugin::mysql::database { 'openstack-config':
    host     => $host,
    port     => $port,
    username => $username,
    password => $password,
  }
}
