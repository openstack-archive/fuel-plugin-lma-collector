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
class lma_collector::collectd::ceph_osd
{
  include lma_collector::params
  include collectd::params
  include lma_collector::collectd::service

  $python_module_path = $lma_collector::params::python_module_path

  $modules = {
    'ceph_osd_perf' => {
      'AdminSocket'   => '/var/run/ceph/ceph-*.asok',
    },
  }
  file {"${collectd::params::plugin_conf_dir}/ceph-osd.conf":
    owner   => 'root',
    group   => $collectd::params::root_group,
    mode    => '0644',
    content => template('lma_collector/collectd_python.conf.erb'),
    notify  => Class['lma_collector::collectd::service'],
  }

  lma_collector::collectd::python_script { 'base.py':
  }

  lma_collector::collectd::python_script { 'ceph_osd_perf.py':
  }

}
