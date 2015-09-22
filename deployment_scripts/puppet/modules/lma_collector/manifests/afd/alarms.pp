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

define lma_collector::afd::alarms (
    $type,
    $cluster_name,
    $logical_name,
    $alarms,
    $message_matcher,
) {
    include lma_collector::params
    include lma_collector::service

    $lua_template = inline_template('
local M = {}
setfenv(1, M) -- Remove external access to contain everything in the module

local alarms = {
<% @alarms.each do |alarm_name| -%>
<% @alarms_definitions.each do |alarm| -%>
<% if alarm_name == alarm["name"] -%>
  {
    name = \'<%= alarm_name %>\',
    description = \'<%= alarm["description"] %>\',
    severity = \'<%= alarm["severity"] %>\',
    trigger = {
<% if alarm["trigger"].key?("logical_operator") -%>
      logical_operator = \'<%= alarm["trigger"]["logical_operator"] %>\'
<% else -%>
      logical_operator = \'or\'
<% end -%>
      rules = {
<% alarm["trigger"]["rules"].each do |rule|  -%>
        metric = \'<%= rule["metric"] %>\',
<% if rule["fields"] -%>
        fields = <%= rule["fields"]  %>,
<% else -%>
        fields = {},
<% end -%>
        relational_operator = \'<%= rule["relational_operator"] %>\',
        threshold = \'<%= rule["threshold"] %>\',
        window = \'<%= rule["window"] %>\',
        periods = \'<%= rule["periods"] ||= 0 %>\',
        function = \'<%= rule["function"] %>\',
<% end -%>
      },
    },
  },
<% end -%>
<% end -%>
<% end -%>
}

return alarms
')

    # Create lua structures that describes alarms
    file { "${alarms_dir}/lma_alarms_${name}.lua":
      ensure => present,
      content => inline_template($lua_template),
    }

    # Create the confguration file for Heka
    heka::filter::sandbox { "afd_${type}_${cluster_name}_${logical_name}":
      config_dir      => $lma_collector::params::config_dir,
      filename        => "${lma_collector::params::plugins_dir}/filters/afd.lua",
      message_matcher => "(Type == \'metric\' || Type == \'heka.sandbox.metric\') && (${message_matcher})",
      ticker_interval => 10,
      config          => {
        afd_type         => $type,
        afd_cluster_name => $cluster_name,
        afd_logical_name => $logical_name,
      },
      notify          => Class['lma_collector::service'],
    }
}


