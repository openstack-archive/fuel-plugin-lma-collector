#    Copyright 2016 Mirantis, Inc.
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
require 'spec_helper'

describe 'lma_collector::collectd::ceph' do
    let(:facts) do
        {:kernel => 'Linux', :operatingsystem => 'Ubuntu',
         :osfamily => 'Debian', :concat_basedir => '/foo'}
    end

    describe 'with title set to "pg_mon_status"' do
        let(:title) { :pg_mon_status }
        it { is_expected.to contain_lma_collector__collectd__python('ceph_pg_mon_status') \
             .with_config({}) }
    end

    describe 'with title set to "osd_perf"' do
        let(:title) { :osd_perf }
        it { is_expected.to contain_lma_collector__collectd__python('ceph_osd_perf') \
             .with_config({'AdminSocket' => '/var/run/ceph/ceph-*.asock'}) }
    end
end
