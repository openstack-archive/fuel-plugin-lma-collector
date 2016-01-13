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
define lma_collector::collectd::python (
  $config = {},
) {
  include lma_collector::params
  include lma_collector::collectd::python_base

  validate_hash($config)

  # We use the adapt_collectd_python_plugin_config function to work around
  # a limitation in collectd::plugin::python::module where the config hash
  # cannot include values that are arrays or hashes.  See
  # https://github.com/voxpupuli/puppet-collectd/issues/390.
  $real_config = adapt_collectd_python_plugin_config($config)

  collectd::plugin::python::module { "module_${title}":
    module        => $title,
    modulepath    => $lma_collector::collectd::python_base::modulepath,
    script_source => "puppet:///modules/lma_collector/collectd/${title}.py",
    config        => $real_config,
  }
}
