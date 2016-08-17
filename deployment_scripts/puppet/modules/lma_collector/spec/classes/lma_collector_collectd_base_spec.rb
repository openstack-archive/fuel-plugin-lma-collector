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
require 'spec_helper'

describe 'lma_collector::collectd::base' do
    let(:facts) do
        {:kernel => 'Linux', :operatingsystem => 'Ubuntu',
         :osfamily => 'Debian', :concat_basedir => '/foo',
         :swapsize_mb => 1024}
    end

    describe 'with defaults' do
        it { is_expected.to contain_class('collectd') }
    end

    describe 'with defaults' do
        let(:facts) do
            {:kernel => 'Linux', :operatingsystem => 'Ubuntu',
             :osfamily => 'Debian', :concat_basedir => '/foo',
             :interfaces => 'br-mgmt,en0,bond0,lo', :swapsize_mb => 1024}
        end

        it { is_expected.to contain_class('collectd').with_purge(false) }
        it { is_expected.to contain_class('collectd::plugin::interface').with_interfaces(['en0', 'bond0']) }
    end
end
