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

describe 'lma_collector::elasticsearch' do
    let(:facts) do
        {:kernel => 'Linux', :operatingsystem => 'Ubuntu',
         :osfamily => 'Debian'}
    end

    describe 'with localhost server' do
        let(:params) {{ :server => 'localhost', :port => 9200 }}
        it { is_expected.to contain_heka__output__elasticsearch('elasticsearch') }
        it { is_expected.to contain_heka__encoder__es_json('elasticsearch') }
    end

    describe 'with localhost server and flush_* parameters' do
        let(:params) {{ :server => 'localhost', :port => 9200,
                        :flush_interval => 10, :flush_count => 100,
        }}
        it {
            is_expected.to contain_heka__output__elasticsearch('elasticsearch').with(
                :flush_interval => 10,
                :flush_count => 100,
                :server => 'localhost',
                :port => 9200,
            )
        }
    end
end
