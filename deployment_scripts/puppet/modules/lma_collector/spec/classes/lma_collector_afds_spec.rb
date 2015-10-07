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

describe 'lma_collector::afds' do
    let(:facts) do
        {:kernel => 'Linux', :operatingsystem => 'Ubuntu',
         :osfamily => 'Debian'}
    end

    describe 'with defaults' do
        let(:params) do
            {:roles => ['primary-controller'],
             :node_cluster_roles => [{'controller' => ['primary-controller']}],
             :service_cluster_roles => [{'mysql' => ['primary-controller']}],
             :node_cluster_alarms => [{'controller' => [{'cpu' => ['cpu_warning']}]}],
             :service_cluster_alarms => [{'mysql' => [{'all' => ['db_warning']}]}],
             :alarms => [
                 {"name"=>"cpu_warning",
                  "description"=>"Fake alarm",
                  "severity"=>"warning",
                  "trigger"=>
                   {"logical_operator"=>"or",
                    "rules"=>
                     [{"metric"=>"fake_cpu",
                       "relational_operator"=>">=",
                       "threshold"=>200,
                       "window"=>120,
                       "periods"=>0,
                       "function"=>"avg"}]}},
                 {"name"=>"db_warning",
                  "description"=>"Fake alarm",
                  "severity"=>"warning",
                  "trigger"=>
                   {"logical_operator"=>"or",
                    "rules"=>
                     [{"metric"=>"db-warning",
                       "relational_operator"=>">=",
                       "threshold"=>200,
                       "window"=>120,
                       "periods"=>0,
                       "function"=>"avg"}]}}]}
        end

        it { is_expected.to contain_heka__filter__sandbox('afd_node_role_controller_cpu') }
        it { is_expected.to contain_file('/usr/share/heka/lua_modules/lma_alarms_controller_cpu.lua') }

        it { is_expected.to contain_heka__filter__sandbox('afd_service_mysql_all') }
        it { is_expected.to contain_file('/usr/share/heka/lua_modules/lma_alarms_mysql_all.lua') }
    end
end
