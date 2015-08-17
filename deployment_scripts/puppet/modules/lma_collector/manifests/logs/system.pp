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
class lma_collector::logs::system {
  include lma_collector::params
  include lma_collector::service

  heka::decoder::sandbox { 'system':
    config_dir => $lma_collector::params::config_dir,
    filename   => "${lma_collector::params::plugins_dir}/decoders/generic_syslog.lua" ,
    config     => {
      syslog_pattern          => $lma_collector::params::syslog_pattern,
      fallback_syslog_pattern => $lma_collector::params::fallback_syslog_pattern
    },
    notify     => Class['lma_collector::service'],
  }

  heka::input::logstreamer { 'system':
    config_dir     => $lma_collector::params::config_dir,
    decoder        => 'system',
    file_match     => '(?P<Service>daemon\.log|cron\.log|kern\.log|auth\.log|syslog|messages|debug)',
    differentiator => '[ \'system.\', \'Service\' ]',
    require        => Heka::Decoder::Sandbox['system'],
    notify         => Class['lma_collector::service'],
  }
}
