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

describe 'lma_collector::heka' do
    let(:facts) do
        {:kernel => 'Linux', :operatingsystem => 'Ubuntu',
         :osfamily => 'Debian'}
    end

    describe 'log_collector with default' do
        let(:title) { :log_collector}
        it {
            should contain_heka('log_collector').with(
                'user'     => 'heka',
                'poolsize' => 100,
            )
            should contain_heka__output__tcp('metric')
            should contain_heka__filter__sandbox('heka_monitoring_log_collector')
            should contain_heka__output__dashboard('dashboard_log_collector' )
        }
    end
    describe 'metric_collector with default' do
        let(:title) { :metric_collector}
        it {
            should contain_heka('metric_collector').with(
                'user'     => 'heka',
                'poolsize' => 100,
            )
            should contain_heka__input__tcp('metric')
            should contain_heka__decoder__sandbox('metric' )
            should contain_heka__filter__sandbox('heka_monitoring_metric_collector')
            should contain_heka__output__dashboard('dashboard_metric_collector' )
        }
    end
    describe 'with an invalid title' do
        let(:title) { :invalidname}
        it do
            expect {
                is_expected.to compile
            }.to raise_error(/title must be either/)
        end
    end
    describe 'metric_collector with no self-monitoring and poolsize' do
        let(:title) { :metric_collector}
        let(:params) do
            { :heka_monitoring => false,
              :poolsize => 42,
              :user => 'foo',
            }
        end
        it {
            should contain_heka('metric_collector').with(
                'user'     => 'foo',
                'poolsize' => 42,
            )
            should contain_heka__input__tcp('metric')
            should contain_heka__decoder__sandbox('metric' )
            should contain_heka__filter__sandbox('heka_monitoring_metric_collector').with(
              'ensure' => 'absent'
            )
            should contain_heka__output__dashboard('dashboard_metric_collector' ).with(
              'ensure' => 'absent'
            )
        }
    end
end
