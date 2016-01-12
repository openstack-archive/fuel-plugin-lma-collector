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
  $master_resource = undef,
) {

  validate_array($resources)

  lma_collector::collectd::python { 'pacemaker_resource':
    config => {
      'Resource' => $resources,
    },
  }

  if $master_resource {

    if ! member($resources, $master_resource) {
      fail("${master_resource} not a member of ${resources}")
    }

    # Configure a PostCache chain to create a collectd notification each time
    # the pacemaker_resource plugin generates a metric whose "type instance"
    # matches the resource specified by the $master_resource parameter.
    #
    # The notifications are caught by other plugins to know the state of that
    # Pacemaker resource.

    collectd::plugin { 'target_notification': }
    collectd::plugin { 'match_regex': }

    class { 'collectd::plugin::chain':
      chainname     => 'PostCache',
      defaulttarget => 'write',
      rules         => [
        {
          'match'   => {
            'type'    => 'regex',
            'matches' => {
              'Plugin'       => '^pacemaker_resource$',
              'TypeInstance' => "^${master_resource}$",
            },
          },
          'targets' => [
            {
              'type'       => 'notification',
              'attributes' => {
                'Message'  => '{\"resource\":\"%{type_instance}\",\"value\":%{ds:value}}',
                'Severity' => 'OKAY',
              },
            },
          ],
        },
      ],
    }

  }

}
