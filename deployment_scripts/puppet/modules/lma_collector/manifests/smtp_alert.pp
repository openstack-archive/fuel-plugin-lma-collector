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
class lma_collector::smtp_alert (
  $send_from       = undef,
  $send_to         = [],
  $environment_id  = undef,
  $subject         = $lma_collector::params::smtp_subject,
  $host            = '127.0.0.1:25',
  $auth            = 'none',
  $user            = undef,
  $password        = undef,
  $send_interval   = $lma_collector::params::smtp_send_interval,
  $ensure          = present,
) inherits lma_collector::params {

  include lma_collector::service

  if $host == undef {
    fail('host parameter is undef!')
  }
  $address_port = split($host, ':')
  if count($address_port) == 1 { # missing port
    $host_address_port = "${host}:25"
  } else {
    $host_address_port = $host
  }

  heka::encoder::sandbox { 'smtp_alert':
    config_dir => $lma_collector::params::config_dir,
    filename   => "${lma_collector::params::plugins_dir}/encoders/status_smtp.lua",
    notify     => Class['lma_collector::service'],
  }

  $_subject = "${subject} environment ${environment_id}"
  heka::output::smtp { 'smtp_alert':
    config_dir      => $lma_collector::params::config_dir,
    send_from       => $send_from,
    send_to         => $send_to,
    message_matcher => 'Type == \'heka.sandbox.status\' && Fields[updated] == TRUE',
    encoder         => 'smtp_alert',
    subject         => $_subject,
    host            => $host_address_port,
    auth            => $auth,
    user            => $user,
    password        => $password,
    send_interval   => $send_interval,
  }
}
