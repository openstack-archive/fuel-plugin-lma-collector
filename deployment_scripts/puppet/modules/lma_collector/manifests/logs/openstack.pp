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
define lma_collector::logs::openstack {

  include lma_collector::params
  include lma_collector::service
  include lma_collector::logs::openstack_decoder_splitter

  heka::input::logstreamer { $title:
    config_dir     => $lma_collector::params::config_dir,
    log_directory  => "/var/log/$title",
    decoder        => 'openstack',
    splitter       => 'openstack',
    file_match     => '(?P<Service>.+)\.log$',
    differentiator => "['$title-', 'Service']",
    require        => Class['lma_collector::logs::openstack_decoder_splitter'],
    notify         => Class['lma_collector::service'],
  }
}
