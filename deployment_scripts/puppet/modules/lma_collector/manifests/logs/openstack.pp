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

#
# == Define: lma_collector::logs::openstack
#
# Declaring this defined type creates an Heka logstreamer that reads logs of
# an OpenStack service. The logstreamer is automatically configured with an
# Heka decoder and an Heka splitter appropriate for OpenStack logs.
#
# It works for "standard" OpenStack services that write their logs into log files
# located in /var/log/{service}, where {service} is the service name.
#
define lma_collector::logs::openstack (
  $service_match = '.+',
) {

  # Note: $log_directory could be made configurable in the future.

  include lma_collector::params
  include lma_collector::service::log
  include lma_collector::logs::openstack_decoder_splitter

  heka::input::logstreamer { $title:
    config_dir     => $lma_collector::params::log_config_dir,
    log_directory  => "/var/log/${title}",
    decoder        => 'openstack',
    splitter       => 'openstack',
    file_match     => "(?P<Service>${service_match})\\.log\\.?(?P<Seq>\\d*)$",
    differentiator => "['${title}', '_', 'Service']",
    priority       => '["^Seq"]',
    require        => Class['lma_collector::logs::openstack_decoder_splitter'],
    notify         => Class['lma_collector::service::log'],
  }
}
