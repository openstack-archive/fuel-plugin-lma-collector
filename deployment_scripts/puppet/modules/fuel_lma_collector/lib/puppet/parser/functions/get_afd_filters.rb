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
# ARG4: Hash table mapping metric names to the place where there are collected.
#
# Ex:
#
# ARG0:
#  {"rabbitmq"=>{"apply_to_node" => "controller", "members" => {"queue"=> {"alarms" => ["rabbitmq-queue-warning"]}}},
#   "apache"=>{"apply_to_node" => "controller", "members" => {"worker"=> {"alarms" => ["apache-warning"]}}},
#   "memcached"=>{"apply_to_node"=>"controller", "members" => {"all"=> {"alarms" => ["memcached-warning"]}}},
#   "haproxy"=>{"apply_to_node" => "controller", "members" => {"alive"=> {"alarms" => ["haproxy-warning"]}}}}
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
# ARG4: {"openstack_nova_total_free_vcpus" => {"collected_on": "aggregator"}}
#
# Results -> {
#              'rabbitmq_queue' => {
#                'type' => 'service',
#                'cluster_name' => 'rabbitmq',
#                'logical_name' => 'queue',
#                'alarms' => ['rabbitmq-queue-warning'],
#                'alarms_definitions' => {...},
#                'message_matcher' => "Fields[name] == 'rabbitmq_messages'"
#                'enable_notification' => true,
#                'activate_alerting' => true,
#              },
#              'apache_worker' => {
#                'type' => 'service',
#                'cluster_name' => 'apache',
#                'logical_name' => 'worker',
#                'alarms' => ['apache-warning'],
#                'alarms_definitions' => {...},
#                'message_matcher' => "Fields[name] == 'apache_idle_workers' || Fields[name] == 'apache_status'"
#                'enable_notification' => true,
#                'activate_alerting' => true,
#              }
#            }

module Puppet::Parser::Functions
  newfunction(:get_afd_filters, :type => :rvalue) do |args|

    afd_alarms = args[0]
    alarm_definitions = args[1]
    afd_profiles = args[2]
    type = args[3]
    if not args[4]
        metric_defs = {}
    else
        metric_defs = args[4]
    end
    afd_filters = {}

    afd_alarms.each do |cluster_name , afds|
        if afds.has_key?('apply_to_node')
            default_profile = afds['apply_to_node']
        else
            default_profile = false
        end

        activate_alerting=true
        enable_notification=false
        if afds.has_key?('alerting')
            if afds['alerting'] == 'disabled'
                activate_alerting=false
            elsif afds['alerting'] == 'enabled_with_notification'
                enable_notification = true
            end
        end
        afds['members'].each do |afd_name, alarms|
            metrics = Set.new([])
            matches = false
            if alarms.has_key?('alerting')
                if alarms['alerting'] == 'disabled'
                    activate_alerting=false
                elsif alarms['alerting'] == 'enabled_with_notification'
                    enable_notification = true
                end
            end
            alarms['alarms'].each do |a_name|
                afd = alarm_definitions.select {|defi| defi['name'] == a_name}
                next if afd.empty? # user mention an unknown alarm for this AFD

                afd[0]['trigger']['rules'].each do |r|
                    if metric_defs.has_key?(r['metric']) and metric_defs[r['metric']].has_key?('collected_on') and afd_profiles.include? metric_defs[r['metric']]['collected_on']
                        matches = true
                    elsif afd_profiles.include?(default_profile)
                        matches = true
                    end
                    if matches
                        metrics << r['metric']
                    end
                end
            end
            if matches
                message_matcher = metrics.collect{|x| "Fields[name] == \'#{x}\'" }.join(' || ')
                afd_filters["#{cluster_name}_#{afd_name}"] = {
                    'type' => type,
                    'cluster_name' => cluster_name,
                    'logical_name' => afd_name,
                    'alarms' => alarms['alarms'],
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
