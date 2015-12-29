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

describe 'lma_collector::collectd::pacemaker' do
    let(:facts) do
        {:kernel => 'Linux', :operatingsystem => 'Ubuntu',
         :osfamily => 'Debian', :concat_basedir => '/foo'}
    end

    describe 'with "resources" param' do
        let(:params) {{:resources => ['vip__public', 'vip__management']}}
        it { is_expected.to contain_lma_collector__collectd__python('pacemaker_resource') \
             .with_config({'Resource' => ['vip__public', 'vip__management']}) }
        it { is_expected.not_to contain_collectd__plugin('target_notification') }
        it { is_expected.not_to contain_collectd__plugin('match_regex') }
        it { is_expected.not_to contain_class('collectd::plugin::chain') }
    end

    describe 'with "master_resource" param' do
        let(:params) do
            {:resources => ['vip__public', 'vip__management'],
             :master_resource => 'vip__management'}
        end
        it { is_expected.to contain_lma_collector__collectd__python('pacemaker_resource') \
             .with_config({'Resource' => ['vip__public', 'vip__management']}) }
        it { is_expected.to contain_collectd__plugin('target_notification') }
        it { is_expected.to contain_collectd__plugin('match_regex') }
        it { is_expected.to contain_class('collectd::plugin::chain') }
    end
end
