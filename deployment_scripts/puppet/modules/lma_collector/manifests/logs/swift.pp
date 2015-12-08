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
# == Class lma_collector::logs::swift
#
# Class that configures Heka for reading Swift logs.
#
# The following rsyslog pattern is assumed:
#
# <%PRI%>%TIMESTAMP% %HOSTNAME% %syslogtag%%msg:::sp-if-no-1st-sp%%msg%\n
#
# Swift only uses syslog and doesn't add its logs to log files located in a
# /var/log/swift/ directory as other OpenStack services do. So we make Swift a
# special case and assume rsyslog is used.
#
# === Parameters:
#
# [*file_match*]
#   (mandatory) The log file name pattern. Example: 'swift\.log$'.
#
# [*log_directory*]
#   (optional) The log directory. Default is /var/log.
#
class lma_collector::logs::swift (
  $file_match,
  $log_directory = $lma_collector::params::log_directory,
) inherits lma_collector::params {
  include lma_collector::service

  # Note: syslog_pattern could be made configurable in the future.

  heka::decoder::sandbox { 'swift':
    config_dir => $lma_collector::params::config_dir,
    filename   => "${lma_collector::params::plugins_dir}/decoders/generic_syslog.lua",
    config     => {
      syslog_pattern          => $lma_collector::params::syslog_pattern,
      fallback_syslog_pattern => $lma_collector::params::fallback_syslog_pattern
    },
    notify     => Class['lma_collector::service'],
  }

  heka::input::logstreamer { 'swift':
    config_dir     => $lma_collector::params::config_dir,
    decoder        => 'swift',
    log_directory  => $log_directory,
    file_match     => $file_match,
    differentiator => '[\'openstack.swift\']',
    require        => Heka::Decoder::Sandbox['swift'],
    notify         => Class['lma_collector::service'],
  }
}
