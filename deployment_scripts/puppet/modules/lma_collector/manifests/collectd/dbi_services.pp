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
define lma_collector::collectd::dbi_services (
  $hostname         = 'localhost',
  $username         = undef,
  $password         = undef,
  $dbname           = undef,
  $report_interval  = undef,
  $downtime_factor  = undef,
) {

  include collectd::params
  include lma_collector::collectd::dbi

  $service = $title

  if $report_interval == undef {
    fail('report_interval needs to be defined!')
  }
  if $downtime_factor == undef {
    fail('downtime_factor needs to be defined!')
  }

  # A service is declared 'down' if no heartbeat has been received since
  # "downtime_factor * report_interval" seconds,
  # The "report_interval" must match the corresponding configuration of the
  # service.

  $downtime = $report_interval * $downtime_factor

  if $service == 'nova' or $service == 'cinder' {
    $type = 'services'
  }elsif $service == 'neutron' {
    $type = 'agents'
  }else{
    fail("${service} not supported")
  }

  $plugin_conf_dir = $collectd::params::plugin_conf_dir

  # FIXME(elemoine) we really should use the collectd::plugin::dbi class
  # instead of adding collectd configuration files ourselves. Adding collectd
  # configuration files ourselves forces us to reference to "collectd" service
  # resource, which is private to the "collectd" module.

  file { "${plugin_conf_dir}/dbi_${service}_${type}.conf":
    owner   => 'root',
    group   => $collectd::params::root_group,
    mode    => '0640',
    content => template('lma_collector/collectd_dbi_services.conf.erb'),
    require => Class['lma_collector::collectd::dbi'],
    notify  => Service['collectd'],
  }
}
