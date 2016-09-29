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
#
require 'spec_helper'

describe 'get_afd_filters' do

    alarms_nodes = [
        {"name"=>"cpu-critical-controller",
         "description"=>"The CPU usage is too high (controller node)",
         "severity"=>"critical",
         "trigger"=>
          {"logical_operator"=>"or",
           "rules"=>
            [
                {"metric"=>"cpu_idle",
                 "relational_operator"=>"<=",
                 "threshold"=>5,
                 "window"=>120,
                 "periods"=>0,
                 "function"=>"avg"},
                {"metric"=>"cpu_wait",
                 "relational_operator"=>">=",
                 "threshold"=>35,
                 "window"=>120,
                 "periods"=>0,
                 "function"=>"avg"},
            ]}},
        {"name"=>"cpu-warning-controller",
         "description"=>"The CPU usage is high (controller node)",
         "severity"=>"warning",
         "trigger"=>
          {"logical_operator"=>"or",
           "rules"=>
            [
                {"metric"=>"cpu_idle",
                 "relational_operator"=>"<=",
                 "threshold"=>15,
                 "window"=>120,
                 "periods"=>0,
                 "function"=>"avg"},
                {"metric"=>"cpu_wait",
                 "relational_operator"=>">=",
                 "threshold"=>25,
                 "window"=>120,
                 "periods"=>0,
                 "function"=>"avg"},
            ]}},
        {"name"=>"cpu-critical-compute",
         "description"=>"The CPU usage is high (critical node)",
         "severity"=>"critical",
         "trigger"=>
          {"logical_operator"=>"or",
           "rules"=>
            [
                {"metric"=>"cpu_idle",
                 "relational_operator"=>"<=",
                 "threshold"=>30,
                 "window"=>120,
                 "periods"=>0,
                 "function"=>"avg"},
            ]}},
        {"name"=>"cpu-warning-compute",
         "description"=>"The CPU usage is high (compute node)",
         "severity"=>"warning",
         "trigger"=>
          {"logical_operator"=>"or",
           "rules"=>
            [
                {"metric"=>"cpu_idle",
                 "relational_operator"=>"<=",
                 "threshold"=>20,
                 "window"=>120,
                 "periods"=>0,
                 "function"=>"avg"},
            ]}},
        {"name"=>"fs-critical",
         "description"=>"The FS usage is critical",
         "severity"=>"critical",
         "trigger"=>
          {"logical_operator"=>"or",
           "rules"=>
            [
                {"metric"=>"fs_percent_free",
                 "relational_operator"=>"<=",
                 "threshold"=>8,
                 "window"=>120,
                 "periods"=>0,
                 "function"=>"avg"},
            ]}},
    ]

    afds_nodes = {
        "controller" => {
            "apply_to_node" => "controller",
            "alerting" => 'enabled_with_notification',
            "alarms" => {
                "system" => ["cpu-critical-controller", "cpu-warning-controller"],
            },
        },
        "compute" => {
            "apply_to_node" => "compute",
            "alerting" => 'enabled_with_notification',
            "alarms" => {
                "system" => ["cpu-critical-compute", "cpu-warning-compute"],
                "fs" => ["fs-critical"],
            },
        }
    }

    describe 'For controller nodes' do
        it { should run.with_params(afds_nodes, alarms_nodes, ['controller'], 'node')
             .and_return(
                 {"controller_system"=>
                  {"type"=>"node",
                   "cluster_name"=>"controller",
                   "logical_name"=>"system",
                   "alarms"=>["cpu-critical-controller", "cpu-warning-controller"],
                   "alarms_definitions"=> alarms_nodes,
                   "message_matcher"=>"Fields[name] == 'cpu_idle' || Fields[name] == 'cpu_wait'",
                   "enable_notification" => true,
                   "activate_alerting" => true,
                  }
             })

        }
    end
    describe 'For compute nodes' do
        it { should run.with_params(afds_nodes, alarms_nodes, ['compute'], 'node')
             .and_return(
                 {"compute_system"=>
                  {"type"=>"node",
                   "cluster_name"=>"compute",
                   "logical_name"=>"system",
                   "alarms"=>["cpu-critical-compute", "cpu-warning-compute"],
                   "alarms_definitions"=> alarms_nodes,
                   "message_matcher"=>"Fields[name] == 'cpu_idle'",
                   "activate_alerting" => true,
                   "enable_notification" => true,
                  },
                 "compute_fs"=>
                  {"type"=>"node",
                   "cluster_name"=>"compute",
                   "logical_name"=>"fs",
                   "alarms"=>["fs-critical"],
                   "alarms_definitions"=> alarms_nodes,
                   "message_matcher"=>"Fields[name] == 'fs_percent_free'",
                   "activate_alerting" => true,
                   "enable_notification" => true,
                  }
                })
             }
    end
    describe 'For compute and controller nodes' do
        it { should run.with_params(afds_nodes, alarms_nodes, ['compute', 'controller'], 'node')
             .and_return(
                 {"compute_system"=>
                  {"type"=>"node",
                   "cluster_name"=>"compute",
                   "logical_name"=>"system",
                   "alarms"=>["cpu-critical-compute", "cpu-warning-compute"],
                   "alarms_definitions"=> alarms_nodes,
                   "message_matcher"=>"Fields[name] == 'cpu_idle'",
                   "activate_alerting" => true,
                   "enable_notification" => true,
                  },
                 "compute_fs"=>
                  {"type"=>"node",
                   "cluster_name"=>"compute",
                   "logical_name"=>"fs",
                   "alarms"=>["fs-critical"],
                   "alarms_definitions"=> alarms_nodes,
                   "message_matcher"=>"Fields[name] == 'fs_percent_free'",
                   "activate_alerting" => true,
                   "enable_notification" => true,
                  },
                 "controller_system"=>
                  {"type"=>"node",
                   "cluster_name"=>"controller",
                   "logical_name"=>"system",
                   "alarms"=>["cpu-critical-controller", "cpu-warning-controller"],
                   "alarms_definitions"=> alarms_nodes,
                   "message_matcher"=>"Fields[name] == 'cpu_idle' || Fields[name] == 'cpu_wait'",
                   "activate_alerting" => true,
                   "enable_notification" => true,
                  }
                })
             }
    end

    alarms_services = [
        {"name"=>"rabbitmq-queue-warning",
         "description"=>"Number of message in queues too high",
         "severity"=>"warning",
         "trigger"=>
          {"logical_operator"=>"or",
           "rules"=>
            [{"metric"=>"rabbitmq_messages",
              "relational_operator"=>">=",
              "threshold"=>200,
              "window"=>120,
              "periods"=>0,
              "function"=>"avg"}]}},
        {"name"=>"apache-warning",
         "description"=>"",
         "severity"=>"warning",
         "trigger"=>
          {"logical_operator"=>"or",
           "rules"=>
            [{"metric"=>"apache_idle_workers",
              "relational_operator"=>"=",
              "threshold"=>0,
              "window"=>60,
              "periods"=>0,
              "function"=>"min"},
             {"metric"=>"apache_status",
              "relational_operator"=>"=",
              "threshold"=>0,
              "window"=>60,
              "periods"=>0,
              "function"=>"min"}]}}
    ]
    afds_services = {
        "rabbitmq" => {
            "apply_to_node" => "controller",
            "alerting" => 'enabled',
            "alarms" => {
                "queue" => ["rabbitmq-queue-warning"]
            },
        },
        "apache" => {
            "apply_to_node" => "controller",
            "alerting" => 'enabled',
            "alarms" => {
                "worker" => ['apache-warning'],
            },
        },
    }
    describe 'For services' do
        it { should run.with_params(afds_services, alarms_services, ['controller'], 'service')
             .and_return(
                 {
                     "rabbitmq_queue"=>
                     {
                         "type"=>"service",
                         "cluster_name"=>"rabbitmq",
                         "logical_name"=>"queue",
                         "alarms_definitions"=> alarms_services,
                         "alarms"=>["rabbitmq-queue-warning"],
                         "message_matcher"=>"Fields[name] == 'rabbitmq_messages'",
                         "activate_alerting" => true,
                         "enable_notification" => false,
                     },
                     "apache_worker"=>
                     {
                         "type"=>"service",
                         "cluster_name"=>"apache",
                         "logical_name"=>"worker",
                         "alarms_definitions"=> alarms_services,
                         "alarms"=>["apache-warning"],
                         "message_matcher"=>"Fields[name] == 'apache_idle_workers' || Fields[name] == 'apache_status'",
                         "activate_alerting" => true,
                         "enable_notification" => false,
                     }}

             )
             }
    end
    describe 'For services with apply_to_node overriden by metric collected_on' do
        alarms_services_o = [
            {"name"=>"free_vcpu_warning",
             "description"=>"",
             "severity"=>"warning",
             "trigger"=>
              {"logical_operator"=>"or",
               "rules"=>
                [{"metric"=>"free_vcpu",
                  "relational_operator"=>"<=",
                  "threshold"=>1,
                  "window"=>60,
                  "periods"=>0,
                  "function"=>"min"},
                  ]}},
            {"name"=>"total_free_vcpu_warning",
             "description"=>"",
             "severity"=>"warning",
             "trigger"=>
              {"logical_operator"=>"or",
               "rules"=>
                [{"metric"=>"total_free_vcpu",
                  "relational_operator"=>"<=",
                  "threshold"=>10,
                  "window"=>60,
                  "periods"=>0,
                  "function"=>"min"},
                  ]}},
            {"name"=>"cpu-critical-controller",
             "description"=>"The CPU usage is high (critical node)",
             "severity"=>"critical",
             "trigger"=>
              {"logical_operator"=>"or",
               "rules"=>
                [
                    {"metric"=>"cpu_idle",
                     "relational_operator"=>"<=",
                     "threshold"=>30,
                     "window"=>120,
                     "periods"=>0,
                     "function"=>"avg"},
                ]}},
            {"name"=>"cpu-warning-controller",
             "description"=>"The CPU usage is high (controller node)",
             "severity"=>"warning",
             "trigger"=>
              {"logical_operator"=>"or",
               "rules"=>
                [
                    {"metric"=>"cpu_idle",
                     "relational_operator"=>"<=",
                     "threshold"=>20,
                     "window"=>120,
                     "periods"=>0,
                     "function"=>"avg"},
                ]}},

        ]
        afds_services_overriden = {
            "nova-free-resources" => {
                "apply_to_node" => "compute",
                "alerting" => 'enabled',
                "alarms" => {
                    "free-vcpu" => ['free_vcpu_warning'],
                },
            },
            "nova-total-free-resources" => {
                "alerting" => 'enabled',
                "alarms" => {
                    "total-free-vcpu" => ['total_free_vcpu_warning'],
                },
            },
            "controller" => {
                "apply_to_node" => "controller",
                "alerting" => 'enabled_with_notification',
                "alarms" => {
                    "system" => ["cpu-critical-controller", "cpu-warning-controller"],
                },
            },
        }
        metrics = {
            "free_vcpu" => {
                "collected_on" => "controller"
            },
            "total_free_vcpu" => {
                "collected_on" => "controller"
            }
        }
        it { should run.with_params(afds_services_overriden, alarms_services_o, ['controller'], 'service', metrics)
             .and_return(
                 {
                     "nova-free-resources_free-vcpu"=>
                     {
                         "type"=>"service",
                         "cluster_name"=>"nova-free-resources",
                         "logical_name"=>"free-vcpu",
                         "alarms_definitions"=> alarms_services_o,
                         "alarms"=>["free_vcpu_warning"],
                         "message_matcher"=>"Fields[name] == 'free_vcpu'",
                         "activate_alerting" => true,
                         "enable_notification" => false,
                     },
                     "nova-total-free-resources_total-free-vcpu"=>
                     {
                         "type"=>"service",
                         "cluster_name"=>"nova-total-free-resources",
                         "logical_name"=>"total-free-vcpu",
                         "alarms_definitions"=> alarms_services_o,
                         "alarms"=>["total_free_vcpu_warning"],
                         "message_matcher"=>"Fields[name] == 'total_free_vcpu'",
                         "activate_alerting" => true,
                         "enable_notification" => false,
                     },
                     "controller_system"=>
                     {
                         "type"=>"service",
                         "cluster_name"=>"controller",
                         "logical_name"=>"system",
                         "alarms"=>["cpu-critical-controller", "cpu-warning-controller"],
                         "alarms_definitions"=> alarms_services_o,
                         "message_matcher"=>"Fields[name] == 'cpu_idle'",
                         "enable_notification" => true,
                         "activate_alerting" => true,
                     }
                }
             )
         }
    end
end

