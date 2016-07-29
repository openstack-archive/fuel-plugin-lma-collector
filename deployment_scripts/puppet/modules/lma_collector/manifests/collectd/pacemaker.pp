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

class lma_collector::collectd::pacemaker (
  $resources,
  $notify_resource = undef,
  $hostname = undef,
) {

  validate_hash($resources)

  # Add quotes around the hash keys and values
  $resources_keys = suffix(prefix(keys($resources), '"'), '"')
  $resources_values = suffix(prefix(values($resources), '"'), '"')
  $real_resources = hash(flatten(zip($resources_keys, $resources_values)))

  if $hostname {
    $_hostname = {'Hostname' => "\"${hostname}\""}
  } else {
    $_hostname = {}
  }
  if $notify_resource {
    $_notify_resource = {'NotifyResource' => "\"${notify_resource}\""}
  } else {
    $_notify_resource = {}
  }

  lma_collector::collectd::python { 'collectd_pacemaker':
    config => merge({'Resource' => $real_resources}, $_hostname, $_notify_resource)
  }

  # Remove configuration bits from versions < 1.0
  collectd::plugin { 'target_notification':
    ensure => absent
  }
  collectd::plugin { 'match_regex':
    ensure => absent
  }
  class { 'collectd::plugin::chain':
    ensure => absent
  }
}
