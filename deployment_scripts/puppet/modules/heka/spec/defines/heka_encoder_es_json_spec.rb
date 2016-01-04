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

describe 'heka::encoder::es_json' do
    let(:title) { :es }
    let(:facts) do
        {:kernel => 'Linux', :operatingsystem => 'Ubuntu',
         :osfamily => 'Debian'}
    end

    describe 'with title = es' do
        let(:params) {{:config_dir => '/etc/hekad', :index => 'bar'}}
        it { is_expected.to contain_file('/etc/hekad/encoder-es.toml') }
    end
    describe 'with fields list' do
        let(:params) {{:config_dir => '/etc/hekad', :index => 'bar', :fields => ['foo', 'bar']}}
        it { is_expected.to contain_file('/etc/hekad/encoder-es.toml').with_content(/fields = \[ "bar", "foo" \]/) }
    end
end

