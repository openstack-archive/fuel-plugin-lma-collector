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
require 'yaml'

describe 'fuel_lma_collector::hiera_data' do
    let(:title) { :foo }
    let(:facts) do
        {:kernel => 'Linux', :operatingsystem => 'Ubuntu',
         :osfamily => 'Debian'}
    end

    describe 'with valid YAML' do
        yaml =<<EOF
lma_collector:
  some_parameter: 42
EOF
        let(:params) do
            {:content => yaml}
        end
        it { is_expected.to contain_file('/etc/hiera/override/foo.yaml') }
    end

    describe 'with invalid YAML' do
        yaml =<<EOF
lma_collector:
  some_parameter: "ee
EOF
        let(:params) do
            {:content => yaml}
        end
        it do
            skip('needs stdlib >= 4.9.0')
            is_expected.to raise_error(Psych::SyntaxError)
        end
    end

    describe 'with data which is not a hash' do
        yaml =<<EOF
lma_collector
EOF
        let(:params) do
            {:content => yaml}
        end
        it { is_expected.to raise_error(Puppet::Error) }
    end

    describe 'with missing key in YAML' do
        yaml =<<EOF
not_lma_collector:
  some_parameter: 42
EOF
        let(:params) do
            {:content => yaml}
        end
        it { is_expected.to raise_error(Puppet::Error) }
    end
end
