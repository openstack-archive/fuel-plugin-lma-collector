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

describe 'lma_collector::gse_cluster_filter' do
    let(:title) { :service }
    let(:facts) do
        {:kernel => 'Linux', :operatingsystem => 'Ubuntu',
         :osfamily => 'Debian'}
    end

    describe 'with defaults' do
        let(:params) do
            {:input_message_types => ['afd_service_metric'],
             :aggregator_flag => true,
             :cluster_field => 'service',
             :member_field => 'source',
             :output_message_type => 'gse_service_cluster_metric',
             :output_metric_name => 'cluster_service_status'}
        end
        it { is_expected.to contain_heka__filter__sandbox('gse_service').with_message_matcher("(Fields[name] == 'internal_status' && Fields[internal] == 'aggregator') || (Fields[aggregator] != NIL && (Type =~ /afd_service_metric$/))") }
        it { is_expected.to contain_file('gse_service_topology') }
    end

    describe 'with dependencies' do
        let(:params) do
            {:input_message_types => ['gse_service_cluster_metric', 'gse_node_cluster_metric'],
             :aggregator_flag => false,
             :member_field => 'cluster_name',
             :output_message_type => 'gse_cluster_metric',
             :output_metric_name => 'cluster_status',
             :warm_up_period => 30,
             :clusters => {
                'nova' => {
                    'members' => ['nova-api', 'nova-scheduler', 'controller_nodes'],
                    'group_by' => 'member',
                    'hints' => ['keystone'],
                    'policy' => 'some_policy'
                },
                'keystone' => {
                    'members' => ['keystone-public-api', 'keystone-admin-api', 'controller_nodes'],
                    'group_by' => 'member',
                    'policy' => 'some_policy'
                }
             }
            }
        end
        it { is_expected.to contain_heka__filter__sandbox('gse_service').with_message_matcher("(Fields[name] == 'internal_status' && Fields[internal] == 'aggregator') || (Fields[aggregator] == NIL && (Type =~ /gse_service_cluster_metric$/ || Type =~ /gse_node_cluster_metric$/))") }
        it { is_expected.to contain_file('gse_service_topology') }
    end
end
