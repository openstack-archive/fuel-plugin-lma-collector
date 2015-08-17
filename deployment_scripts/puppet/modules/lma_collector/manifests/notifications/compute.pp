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
class lma_collector::notifications::compute (
    $topics = [],
    $driver = $lma_collector::params::notification_driver,
) inherits lma_collector::params {
  include lma_collector::service

  validate_array($topics)

  include nova::params

  nova_config { 'DEFAULT/notification_topics':
    value  => join($topics, ','),
    notify => Service[$::nova::params::compute_service_name],
  }
  nova_config { 'DEFAULT/notification_driver':
    value  => $driver,
    notify => Service[$::nova::params::compute_service_name],
  }
  nova_config { 'DEFAULT/notify_on_state_change':
    value  => 'vm_and_task_state',
    notify => Service[$::nova::params::compute_service_name],
  }

  service { $::nova::params::compute_service_name:
    hasstatus  => true,
    hasrestart => true,
  }
}
