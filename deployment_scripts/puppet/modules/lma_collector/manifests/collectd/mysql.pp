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
  $database = $lma_collector::params::mysql_database,
  $username = $lma_collector::params::mysql_username,
  $password = $lma_collector::params::mysql_password,
) inherits lma_collector::params {
  include lma_collector::collectd::service

  collectd::plugin::mysql::database { $database:
    host     => 'localhost',
    username => $username,
    password => $password,
    notify   => Class['lma_collector::collectd::service'],
  }
}
