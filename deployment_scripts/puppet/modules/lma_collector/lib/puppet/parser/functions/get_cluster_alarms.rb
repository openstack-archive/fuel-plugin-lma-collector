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
# ARG0:
#    node_cluster_alarms:
#      - controller:
#        - system: ['cpu-critical-controller', 'cpu-warning-controller']
#        - fs: ['fs-warning', 'fs-critical']
#      - _default:
#        - cpu: ['cpu-critical-default']
#        - fs: ['fs-warning-default', 'fs-critical-default']
#    service_cluster_alarms:
#      - rabbitmq:
#        - queue: ['rabbitmq-queue-warning']
#
# ARG1: {'node' => [controller],
#        'service' => [rabbitmq]}
#
# Results -> {
#              'controller_system' => {
#                'type' => 'node',
#                'cluster_name' => 'controller',
#                'logical_name' => 'system',
#                'alarms' => ['cpu-critical-controller', 'cpu-warning-controller'],
#                'message_matcher' => "Fields[name] == 'cpu_idle' || Fields[name] == 'cpu_wait'"
#              },
#              'controller_fs' => {
#                'type' => 'node',
#                'cluster_name' => 'controller',
#                'logical_name' => 'fs',
#                'alarms' => ['fs-warning', 'fs-critical'],
#              },
#            ...
#            }

module Puppet::Parser::Functions
  newfunction(:fill_alarms) do |args|
     name = args[0]
     alarms = args[1]
     alarms_list = args[2]
     alarms_definitions = args[3]
     type = args[4]

     # We need to get the list of metrics associated to alarms
     alarms_list.each do |alarm_hash|
       alarm_hash.each do |alarm_name, alarm_list|
         # Get the list of metrics associated to alarm_list to
         # build the message matcher
         metrics = [].to_set
         alarm_list.each do |alarm|
           alarms_definitions.each do |definition|
             if definition['name'] == alarm
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

         alarms["#{name}_#{alarm_name}".sub(/^_/, '')] = {
             'type' => type,
             'cluster_name' => name,
             'logical_name' => alarm_name,
             'alarms' => alarm_list,
             'message_matcher' => message_matcher
         }
       end
     end
  end

  newfunction(:get_cluster_alarms, :type => :rvalue) do |args|

    data = args[0]
    cluster_list = args[1]
    alarms = {}

    # Fill alarms related to node
    nca = data['node_cluster_alarms']

    cluster_list['node'].each do |cn|
      # nca is a table of hash. We need to check if the node name is a key in this hash
      # otherwise we will use _default value.
      nca.each do |nca_hash|
        nca_hash.each do |k1, v1|
          if k1 == cn
            function_fill_alarms([cn, alarms, v1, data['alarms'], 'node'])
            break
          end
        end
      end

    end # alarms related to node

    # And now alarms related to service
    sca = data['service_cluster_alarms']

    cluster_list['service'].each do |cn|
      sca.each do |sca_hash|
        sca_hash.each do |k1, v1|
          if k1 == cn
            function_fill_alarms([cn, alarms, v1, data['alarms'], 'service'])
            break
          end
        end
      end
    end # alarms related to service

    return alarms
  end
end
