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

describe 'heka' do
    let(:facts) do
        {:kernel => 'Linux', :operatingsystem => 'Ubuntu',
         :osfamily => 'Debian'}
    end

    describe 'with defaults' do
        let(:title) { :log}
        it { is_expected.to contain_user('heka') }
        it { is_expected.to contain_file('/etc/init/log.conf') \
             .with_content(/--chuid heka/) }
    end

    describe 'with user => "root"' do
        let(:params) do
            {:user => 'root'}
        end
        let(:title) { :foo}

        it { is_expected.to contain_user('root') }
        it { is_expected.to contain_file('/etc/init/foo.conf') }
        it { is_expected.not_to contain_file('/etc/init/foo.conf') \
             .with_content(/--chuid/) }
    end
end
