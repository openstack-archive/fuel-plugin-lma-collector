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

describe 'lma_collector::influxdb' do
    let(:facts) do
        {:kernel => 'Linux', :operatingsystem => 'Ubuntu',
         :osfamily => 'Debian'}
    end

    describe 'with mandatory parameters' do
        let(:params) {{ :server => 'localhost', :port => 8086, :user => 'lma',
                        :password => 'lma', :database => 'lma' }}
        it { is_expected.to contain_heka__output__http('influxdb') }
        it { is_expected.to contain_heka__encoder__payload('influxdb') }
        it { is_expected.to contain_heka__filter__sandbox('influxdb_accumulator') }
        it { is_expected.to contain_heka__filter__sandbox('influxdb_annotation') }
    end

    describe 'with tag_fields parameter' do
        let(:params) {{ :server => 'localhost', :port => 8086, :user => 'lma',
                        :password => 'lma', :database => 'lma',
                        :tag_fields => ['foo', 'zzz'] }}
        it { is_expected.to contain_heka__output__http('influxdb') }
        it { is_expected.to contain_heka__encoder__payload('influxdb') }
        it { is_expected.to contain_heka__filter__sandbox('influxdb_accumulator').with_config({
            "tag_fields" => "foo hostname zzz", "flush_interval"=> :undef,
            "flush_count"=> :undef, "time_precision" => "ms"}) }
        it { is_expected.to contain_heka__filter__sandbox('influxdb_annotation') }
    end
end
