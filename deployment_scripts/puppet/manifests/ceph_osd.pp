# Copyright 2015 Mirantis, Inc.
#
# Licensed under the Apache License, Version 2.0 (the "License"); you may
# not use this file except in compliance with the License. You may obtain
# a copy of the License at
#
#      http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS, WITHOUT
# WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. See the
# License for the specific language governing permissions and limitations
# under the License.

notice('fuel-plugin-lma-collector: ceph_osd.pp')

if hiera('lma::collector::influxdb::server', false) {
  # Only install this python collectd plugin if ceph-osd is not deployed on a
  # controller node. This is due to a limitation of the python plugin puppet
  # module which can be run only by one manifest otherwise the collectd configuration is
  # overwritten by the next run. Currently only controller nodes have python
  # plugins installed so it's safe to install on all other roles .. for now.
  if ! roles_include(['controller', 'primary-controller']) {
    class { 'lma_collector::collectd::base':
      processes    => ['hekad', 'collectd'],
    }
    class { 'lma_collector::collectd::ceph_osd': }
  }else{
    notice('ceph_osd_perf not configured to avoid messing of collectd python plugin configuration!')
  }
}
