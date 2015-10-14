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

describe 'lma_collector::afd_nagios' do
    let(:facts) do
        {:kernel => 'Linux', :operatingsystem => 'Ubuntu',
         :osfamily => 'Debian'}
    end
    describe 'with defaults' do
        let(:title) { :node}
        let(:params) do
            {:roles => ['primary-controller'],
             :cluster_roles => [{'controller' => ['primary-controller']}],
             :alarms => [{'controller' => [{'cpu' => ['cpu_warning']}]}],
             :url => 'http://foo',
             :user => 'u',
             :password => 'p',
             :hostname => 'foohost',
            }
        end
        it { is_expected.to contain_heka__encoder__sandbox('nagios_afd_node').with('config' => {
                                                                "controller.cpu" => "controller.cpu",
                                                                "nagios_host" => "foohost",
                                                                "field_service_1" => "node_role",
                                                                "field_service_2" => "source",
                                                                "prefix_service"=>"foohost."})
        }
        it { is_expected.to contain_heka__output__http('nagios_afd_node').with(
                                "url" => "http://foo"
        )}
    end
end
