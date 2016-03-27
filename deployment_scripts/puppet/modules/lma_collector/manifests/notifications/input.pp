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
class lma_collector::notifications::input (
    $topic,
    $user,
    $password,
    $host,
    $port = $lma_collector::params::rabbitmq_port,
) inherits lma_collector::params {

  include lma_collector::service::log

  $lua_modules_dir = $lma_collector::params::lua_modules_dir

  validate_string($topic)
  validate_string($user)
  validate_string($password)
  validate_string($host)
  validate_integer($port)

  # We need to pick one exchange and we settled on 'nova'. The default
  # exchange ("") doesn't work because Heka would fail to create the queue in
  # case it doesn't exist yet.
  $exchange = 'nova'

  $config_dir = $lma_collector::params::log_config_dir
  heka::decoder::sandbox { 'notification':
    config_dir       => $config_dir,
    filename         => "${lma_collector::params::plugins_dir}/decoders/notification.lua" ,
    config           => {
      include_full_notification => false
    },
    module_directory => $lua_modules_dir,
    notify           => Class['lma_collector::service::log'],
  }

  create_resources(
    heka::input::amqp,
    {
      'openstack_info' => {
        queue                => "${topic}.info",
        routing_key          => "${topic}.info",
      },
      'openstack_warn' => {
        queue                => "${topic}.warn",
        routing_key          => "${topic}.warn",
      },
      'openstack_error' => {
        queue                => "${topic}.error",
        routing_key          => "${topic}.error",
      },
    },
    {
      config_dir           => $config_dir,
      decoder              => 'notification',
      user                 => $user,
      password             => $password,
      host                 => $host,
      port                 => $port,
      exchange             => $exchange,
      exchange_durability  => false,
      exchange_auto_delete => false,
      queue_auto_delete    => false,
      exchange_type        => 'topic',
      notify               => Class['lma_collector::service::log'],
    }
  )
}
