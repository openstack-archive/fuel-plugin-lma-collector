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
#
# Returns a hash describing the AFD filter resources for the given inputs.
#
# ARG0: Hash table mapping AFD profiles to alarms
# ARG1: Array of alarm definitions
# ARG2: Array of AFD profiles
# ARG3: Type of AFD (either 'node' or 'service')
#
# Ex:
#
# ARG0:
#  {"rabbitmq"=>{"apply_to_node" => "controller", "alarms" => {"queue"=>["rabbitmq-queue-warning"]}},
#   "apache"=>{"apply_to_node" => "controller", "alarms" => {"worker"=>["apache-warning"]}},
#   "memcached"=>{"apply_to_node"=>"controller", "alarms" => {"all"=>["memcached-warning"]}},
#   "haproxy"=>{"apply_to_node" => "controller", "alarms" => {"alive"=>["haproxy-warning"]}}}
#
# ARG1:
#
#  [
#    {"name"=>"rabbitmq-queue-warning",
#     "description"=>"Number of message in queues too high",
#     "severity"=>"warning",
#     "trigger"=>
#      {"logical_operator"=>"or",
#       "rules"=>
#        [{"metric"=>"rabbitmq_messages",
#          "relational_operator"=>">=",
#          "threshold"=>200,
#          "window"=>120,
#          "periods"=>0,
#          "function"=>"avg"}]}},
#    {"name"=>"apache-warning",
#     "description"=>"",
#     "severity"=>"warning",
#     "trigger"=>
#      {"logical_operator"=>"or",
#       "rules"=>
#        [{"metric"=>"apache_idle_workers",
#          "relational_operator"=>"=",
#          "threshold"=>0,
#          "window"=>60,
#          "periods"=>0,
#          "function"=>"min"},
#         {"metric"=>"apache_status",
#          "relational_operator"=>"=",
#          "threshold"=>0,
#          "window"=>60,
#          "periods"=>0,
#          "function"=>"min"}]}}
#   ]
#
# ARG2: ["controller", "compute"]
#
# ARG3: type (node|service)
#
# Results -> {
#              'rabbitmq_queue' => {
#                'type' => 'service',
#                'cluster_name' => 'rabbitmq',
#                'logical_name' => 'queue',
#                'alarms' => ['rabbitmq-queue-warning'],
#                'alarms_definitions' => {...},
#                'message_matcher' => "Fields[name] == 'rabbitmq_messages'"
#              },
#              'apache_worker' => {
#                'type' => 'service',
#                'cluster_name' => 'apache',
#                'logical_name' => 'worker',
#                'alarms' => ['apache-warning'],
#                'alarms_definitions' => {...},
#                'message_matcher' => "Fields[name] == 'apache_idle_workers' || Fields[name] == 'apache_status'"
#              }
#            }

module Puppet::Parser::Functions
  newfunction(:get_afd_filters, :type => :rvalue) do |args|

    afd_alarms = args[0]
    alarm_definitions = args[1]
    afd_profiles = args[2]
    type = args[3]
    afd_filters = {}

    afd_profiles.each do |afd_profile|
        afds = afd_alarms.select {|k,v| v.has_key?('apply_to_node') and v['apply_to_node'] == afd_profile }
        afds.each do |k, v|
            activate_alerting=true
            if v.has_key?('activate_alerting')
                if v['activate_alerting'] == false
                    activate_alerting=false
                end
            end
            enable_notification=false
            if v.has_key?('enable_notification')
                if v['enable_notification'] == true
                    enable_notification=true
                end
            end
            afd_cluster_name = k
            v['alarms'].each do |afd_name, alarms|
                # Collect the metrics which are required by this AFD filter
                metrics = Set.new([])
                alarms.each do |a_name|
                    alarm_definitions.each do |alarm_def|
                        if alarm_def['name'] == a_name
                            alarm_def['trigger']['rules'].each do |r|
                                metrics << r['metric']
                            end
                        end

                    end
                end
                message_matcher = metrics.collect{|x| "Fields[name] == \'#{x}\'" }.join(' || ')

                afd_filters["#{afd_cluster_name}_#{afd_name}"] = {
                    'type' => type,
                    'cluster_name' => afd_cluster_name,
                    'logical_name' => afd_name,
                    'alarms' => alarms,
                    'alarms_definitions' => alarm_definitions,
                    'message_matcher' => message_matcher,
                    'activate_alerting' => activate_alerting,
                    'enable_notification' => enable_notification,
                }
            end
        end
    end

    return afd_filters
  end
end
