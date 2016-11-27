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
class lma_collector::alarms_tcp_notifier (
) inherits lma_collector::params {

  include lma_collector::service::metric

  $lua_modules_dir = $lma_collector::params::lua_modules_dir

  $matcher = join(["Type == 'heka.sandbox.gse_cluster_metric'",
                     "Type == 'heka.sandbox.gse_node_cluster_metric'",
                     "Type == 'heka.sandbox.gse_service_cluster_metric'",
                     "Fields[aggregator] == NIL && Type == 'heka.sandbox.afd_node_metric'",
                     "Fields[aggregator] == NIL && Type == 'heka.sandbox.afd_service_metric'",], ' || ')

  heka::filter::sandbox { 'alarms_tcp_notifier':
    config_dir       => $lma_collector::params::metric_config_dir,
    filename         => "${lma_collector::params::plugins_dir}/filters/alarms_tcp_notifier.lua",
    message_matcher  => $matcher,
    config           => {
    },
    module_directory => $lua_modules_dir,
    notify           => Class['lma_collector::service::metric'],
  }
}
