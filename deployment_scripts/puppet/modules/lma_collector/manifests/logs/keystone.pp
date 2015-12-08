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
# == Class lma_collector::logs::keystone
#
# Class that configures Heka for reading Keystone logs.
#
# The following rsyslog pattern is assumed:
#
# <%PRI%>%TIMESTAMP% %HOSTNAME% %syslogtag%%msg:::sp-if-no-1st-sp%%msg%\n
#
# We rely on syslog for Keystone because /var/log/keystone is owned by the
# keystone user and we do not have permission to read from that file.
#
# === Parameters:
#
# [*file_match*]
#   (mandatory) The log file name pattern. Example: 'keystone\.log$'.
#
# [*log_directory*]
#   (optional) The log directory. Default is /var/log.
#
class lma_collector::logs::keystone (
  $file_match,
  $log_directory = $lma_collector::params::log_directory,
) inherits lma_collector::params {

  include lma_collector::service

  heka::decoder::sandbox { 'keystone':
    config_dir => $lma_collector::params::config_dir,
    filename   => "${lma_collector::params::plugins_dir}/decoders/keystone_7_0_log.lua" ,
    config     => {
      syslog_pattern => $lma_collector::params::syslog_pattern
    },
    notify     => Class['lma_collector::service'],
  }

  heka::input::logstreamer { 'keystone':
    config_dir     => $lma_collector::params::config_dir,
    decoder        => 'keystone',
    file_match     => $file_match,
    differentiator => '[\'openstack.keystone\']',
    require        => Heka::Decoder::Sandbox['keystone'],
    notify         => Class['lma_collector::service'],
  }
}
