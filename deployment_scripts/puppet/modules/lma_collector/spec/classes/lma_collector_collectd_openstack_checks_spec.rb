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

describe 'lma_collector::collectd::openstack_checks' do
    let(:facts) do
        {:kernel => 'Linux', :operatingsystem => 'Ubuntu',
         :osfamily => 'Debian', :concat_basedir => '/foo'}
    end

    describe 'with required params' do
        let(:params) do
            {:user => 'user', :password => 'password', :tenant => 'tenant',
             :keystone_url => 'http://example.com/keystone'}
        end
        it { is_expected.to contain_lma_collector__collectd__python('check_openstack_api') \
             .with_config({"Username" => "user", "Password" => "password",
                           "Tenant" => "tenant",
                           "KeystoneUrl" => "http://example.com/keystone",
                           "Timeout" => "5"}) }
    end

    describe 'with required and optional params' do
        let(:title) { :nova }
        let(:params) {{:user => "user", :password => "password", :tenant => "tenant",
                       :keystone_url => "http://example.com/keystone",
                       :timeout => 10, :pacemaker_master_resource => "vip__management"}}
        it { is_expected.to contain_lma_collector__collectd__python('check_openstack_api') \
             .with_config({"Username" => "user", "Password" => "password",
                           "Tenant" => "tenant",
                           "KeystoneUrl" => "http://example.com/keystone",
                           "Timeout" => "10", "DependsOnResource" => "vip__management"}) }
    end
end
