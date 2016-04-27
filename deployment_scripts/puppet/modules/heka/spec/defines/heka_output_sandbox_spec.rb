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

describe 'heka::output::sandbox' do
    let(:title) { :foo }
    let(:facts) do
        {:kernel => 'Linux', :operatingsystem => 'Ubuntu',
         :osfamily => 'Debian'}
    end

    describe 'with title = foo' do
        let(:params) {{:config_dir => '/etc/hekad', :filename => 'foo.lua'}}
        it { is_expected.to contain_file('/etc/hekad/output-foo.toml').without_content(/module_directory/) }
    end

    describe 'with title = foo and module_directory' do
        let(:params) {{:config_dir => '/etc/hekad', :filename => 'foo.lua', :module_directory => '/tmp'}}
        it { is_expected.to contain_file('/etc/hekad/output-foo.toml').with_content(/module_directory = "\/tmp;/) }
    end

end
