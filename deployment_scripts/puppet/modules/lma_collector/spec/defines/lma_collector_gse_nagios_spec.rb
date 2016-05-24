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

describe 'lma_collector::gse_nagios' do
    let(:title) { :global}
    let(:facts) do
        {:kernel => 'Linux', :operatingsystem => 'Ubuntu',
         :osfamily => 'Debian'}
    end
    let(:params) do
        {:server  => 'nagios.org',
         :http_port => 9999,
         :http_path => 'status',
         :user => 'foo',
         :password => 'secret',
         :message_type => 'foo_type',
         :virtual_hostname => 'foo_vhost'}
    end

    it { should contain_heka__encoder__sandbox('nagios_gse_global') }
    it { should contain_heka__output__http('nagios_gse_global') }
end
