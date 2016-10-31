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
define lma_collector::gse_cluster_filter (
  $input_message_types,
  $aggregator_flag,
  $member_field,
  $output_message_type,
  $output_metric_name,
  $interval = 10,
  $cluster_field = undef,
  $clusters = {},
  $warm_up_period = undef,
  $alerting = 'enabled_with_notification',
  $ensure = present,
) {
  include lma_collector::params
  include lma_collector::service::metric

  $lua_modules_dir = $lma_collector::params::lua_modules_dir

  validate_array($input_message_types)
  validate_string($cluster_field)
  validate_string($member_field)
  validate_string($output_metric_name)
  if size($input_message_types) == 0 {
    fail('input_message_types cannot be empty')
  }

  $topology_file = sanitize_name_for_lua("gse_${title}_topology")
  if $aggregator_flag {
    $aggregator_flag_operator = '!='
  } else {
    $aggregator_flag_operator = '=='
  }

  $message_matcher = join([
    '(Fields[name] == \'pacemaker_local_resource_active\' && Fields[resource] == \'vip__management\') || ',
    "(Fields[${lma_collector::params::aggregator_flag}] ${aggregator_flag_operator} NIL && (",
    inline_template('<%= @input_message_types.collect{|x| "Type =~ /#{x}$/"}.join(" || ") %>'),
    '))',
  ], '')

  if $alerting and $alerting != 'disabled' and $alerting != 'enabled' and
    $alerting != 'enabled_with_notification' {

    fail("alerting parameter must be either 'disabled', 'enabled' or 'enabled_with_notification' instead of ${alerting}")
  }

  if $alerting != 'disabled' {
    $activate_alerting = true
  } else {
    $activate_alerting = false
  }
  if $alerting != 'enabled_with_notification' {
    $enable_notification = true
  } else {
    $enable_notification = false
  }

  heka::filter::sandbox { "gse_${title}":
    config_dir       => $lma_collector::params::metric_config_dir,
    filename         => "${lma_collector::params::plugins_dir}/filters/gse_cluster_filter.lua",
    message_matcher  => $message_matcher,
    ticker_interval  => 1,
    config           => {
      output_message_type => $output_message_type,
      output_metric_name  => $output_metric_name,
      source              => "gse_${title}_filter",
      interval            => $interval,
      topology_file       => $topology_file,
      policies_file       => $lma_collector::params::gse_policies_module,
      cluster_field       => $cluster_field,
      member_field        => $member_field,
      max_inject          => $lma_collector::params::hekad_max_timer_inject,
      warm_up_period      => $warm_up_period,
      enable_notification => $enable_notification,
      activate_alerting   => $activate_alerting,
    },
    module_directory => $lua_modules_dir,
    require          => File[$topology_file],
    notify           => Class['lma_collector::service::metric']
  }

  file { $topology_file:
    ensure  => present,
    path    => "${lua_modules_dir}/${topology_file}.lua",
    content => template('lma_collector/gse_topology.lua.erb'),
    notify  => Class['lma_collector::service::metric']
  }
}
