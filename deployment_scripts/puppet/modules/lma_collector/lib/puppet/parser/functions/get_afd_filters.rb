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

# This returns a hash that contains the filename of the alarm as key and
# list of alarms associated.
#
# ARG0: The hash table with all information
# ARG1: The hash with the list of cluster nodes and cluster services
#
# Ex:
#
# ARG0: cluster alarms
#  [{"rabbitmq"=>[{"queue"=>["rabbitmq-queue-warning"]}]},
#   {"apache"=>[{"worker"=>["apache-warning"]}]},
#   {"memcached"=>[{"all"=>["memcached-warning"]}]},
#   {"haproxy"=>[{"alive"=>["haproxy-warning"]}]}]
#
# ARG1: array of alarms
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
# ARG2: ["rabbitmq", "apache"]
#
# ARG3: type (node|service)
#
# Results -> {
#              'rabbitmq_queue' => {
#                'type' => 'service',
#                'cluster_name' => 'rabbitmq',
#                'logical_name' => 'queue',
#                'alarms' => ['rabbitmq-queue-warning'],
#                'alarms_definition => {...},
#                'message_matcher' => "Fields[name] == 'rabbitmq_messages'"
#              },
#              'apache_worker' => {
#                'type' => 'service',
#                'cluster_name' => 'apache',
#                'logical_name' => 'worker',
#                'alarms' => ['apache-warning'],
#                'alarms_definition => {...},
#                'message_matcher' => "Fields[name] == 'apache_idle_workers' || Fields[name] == 'apache_status'"
#              }
#            }

module Puppet::Parser::Functions
  newfunction(:get_afd_filters, :type => :rvalue) do |args|

    cluster_alarms = args[0]
    alarms_definition = args[1]
    cluster_names = args[2]
    type = args[3]
    afd_filters = {}

    cluster_names.each do |cluster_name|
      # find alarms that belongs to the cluster_name
      cluster_alarms.each do |cluster_alarm|
        cluster_alarm.each do |name, alarms_list|
          if name == cluster_name
            # We need to get the list of metrics associated to alarms
            alarms_list.each do |alarm|
              alarm.each do |alarm_name, alarm_list|

                # Get the list of metrics associated to alarm_list to
                # build the message matcher
                metrics = [].to_set
                alarm_list.each do |a_name|
                  alarms_definition.each do |definition|
                    if definition['name'] == a_name
                      rules = definition['trigger']['rules']
                      rules.each do |r|
                        metrics.add(r['metric'])
                      end
                    end
                  end
                end

                message_matcher = ""
                metrics.each do |m|
                  if message_matcher.empty?
                    message_matcher = "Fields[name] == \'#{m}\'"
                  else
                    message_matcher = message_matcher + " || Fields[name] == \'#{m}\'"
                  end
                end

                afd_filters["#{name}_#{alarm_name}"] = {
                    'type' => type,
                    'cluster_name' => cluster_name,
                    'logical_name' => alarm_name,
                    'alarms' => alarm_list,
                    'alarms_definition' => alarms_definition,
                    'message_matcher' => message_matcher
                }
              end
            end

            break
          end
        end
      end
    end

    return afd_filters
  end
end
