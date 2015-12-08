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

describe 'lma_collector::logs::keystone' do
    let(:facts) do
        {:kernel => 'Linux', :operatingsystem => 'Ubuntu',
         :osfamily => 'Debian'}
    end

    describe 'without file_match' do
        it { is_expected.to raise_error(Puppet::Error, /must pass file_match/i) }
    end

    describe 'with file_match => "keystone\.log$"' do
        let(:params) do
            {:file_match => 'keystone\.log$'}
        end
        it {is_expected.to contain_heka__input__logstreamer('keystone') \
            .with_file_match('keystone\.log$') }
    end
end
