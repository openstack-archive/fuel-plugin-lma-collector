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
             :entity_field => 'service',
             :output_message_type => 'gse_service_cluster_metric',
             :output_metric_name => 'cluster_service_status'}
        end
        it { is_expected.to contain_heka__filter__sandbox('gse_service').with_message_matcher("(Fields[name] == 'pacemaker_local_resource_active' && Fields[resource] == 'vip__management') || (Fields[aggregator] != NIL && (Type =~ /afd_service_metric$/))") }
    end

    describe 'with dependencies' do
        let(:params) do
            {:input_message_types => ['gse_service_cluster_metric', 'gse_node_cluster_metric'],
             :aggregator_flag => false,
             :entity_field => 'cluster_name',
             :output_message_type => 'gse_cluster_metric',
             :output_metric_name => 'cluster_status',
             :level_1_dependencies => {'nova' => ['nova-api','nova-scheduler'],
                                       'cinder' => ['cinder-api']},
             :level_2_dependencies => {'nova-api' => ['neutron-api']}
            }
        end
        it { is_expected.to contain_heka__filter__sandbox('gse_service').with_message_matcher("(Fields[name] == 'pacemaker_local_resource_active' && Fields[resource] == 'vip__management') || (Fields[aggregator] == NIL && (Type =~ /gse_service_cluster_metric$/ || Type =~ /gse_node_cluster_metric$/))") }
    end
end
