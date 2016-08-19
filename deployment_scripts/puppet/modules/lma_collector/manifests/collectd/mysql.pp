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
  $username,
  $password,
  $host = 'localhost',
  $socket = undef,
) inherits lma_collector::params {

  # With "config" as the resource title the collectd configuration
  # file will be named "mysql-config.conf".
  collectd::plugin::mysql::database { 'config':
    host     => $host,
    username => $username,
    password => $password,
    socket   => $socket,
  }

  $default_config = {
      'Host'     => "\"${host}\"",
      'Username' => "\"${username}\"",
      'Password' => "\"${password}\"",
  }

  if $socket {
    $config = merge($default_config, {'Socket'   => "\"${socket}\""})
  } else {
    $config = $default_config
  }

  if $::osfamily == 'RedHat' {
    $pymysql_pkg_name = 'python-PyMySQL'
  } else {
    $pymysql_pkg_name = 'python-pymysql'
  }
  package { $pymysql_pkg_name:
    ensure => present,
  }

  lma_collector::collectd::python { 'collectd_mysql_check':
    config  => $config,
    require => Package[$pymysql_pkg_name],
  }
}
