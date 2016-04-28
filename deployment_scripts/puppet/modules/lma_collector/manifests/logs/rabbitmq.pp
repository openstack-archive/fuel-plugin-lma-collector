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
class lma_collector::logs::rabbitmq {
  include lma_collector::params
  include lma_collector::service

  $lua_modules_dir = $lma_collector::params::lua_modules_dir

  heka::decoder::sandbox { 'rabbitmq':
    config_dir       => $lma_collector::params::config_dir,
    filename         => "${lma_collector::params::plugins_dir}/decoders/rabbitmq.lua" ,
    module_directory => $lua_modules_dir,
    notify           => Class['lma_collector::service'],
  }

  heka::splitter::regex { 'rabbitmq':
    config_dir    => $lma_collector::params::config_dir,
    delimiter     => '\n\n(=[^=]+====)',
    delimiter_eol => false,
    notify        => Class['lma_collector::service'],
  }

  heka::input::logstreamer { 'rabbitmq':
    config_dir     => $lma_collector::params::config_dir,
    decoder        => 'rabbitmq',
    splitter       => 'rabbitmq',
    log_directory  => '/var/log/rabbitmq',
    file_match     => 'rabbit@(?P<Node>.+)\.log$',
    differentiator => '["rabbitmq.", "Node"]',
    require        => [Heka::Decoder::Sandbox['rabbitmq'], Heka::Splitter::Regex['rabbitmq']],
    notify         => Class['lma_collector::service'],
  }
}
