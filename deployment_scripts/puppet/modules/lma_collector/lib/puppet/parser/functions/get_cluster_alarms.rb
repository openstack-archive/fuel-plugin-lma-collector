# This returns a hash that contains the filename of the alarm as key and
# list of alarms associated.
#
# ARG0: The hash table with all informations
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
     type = args[3]

     alarms_list.each do |alarm_hash|
       alarm_hash.each do |alarm_name, alarm_list|
         alarms["#{name}_#{alarm_name}".sub(/^_/, '')] = {
             'type' => type,
             'cluster_name' => name,
             'logical_name' => alarm_name,
             'alarms' => alarm_list
         }
       end
     end
  end

  newfunction(:get_cluster_alarms, :type => :rvalue) do |args|

    data = args[0]
    cluster_list = args[1]
    alarms = {}

    # Fill alarms related to node
    cluster_list['node'].each do |cn|

      nca = data['node_cluster_alarms']

      # nca is a table of hash. We need to check if the node name is a key in this hash
      # otherwise we will use _default value.
      nca.each do |nca_hash|
        nca_hash.each do |k1, v1|
          if k1 == cn
            function_fill_alarms([cn, alarms, v1, 'node'])
            break
          end
        end
      end

    end # alarms related to node

    # And now alarms related to service
    cluster_list['service'].each do |cn|
      sca = data['service_cluster_alarms']
      sca.each do |sca_hash|
        sca_hash.each do |k1, v1|
          if k1 == cn
            function_fill_alarms([cn, alarms, v1, 'service'])
            break
          end
        end
      end
    end # alarms related to service

    return alarms
  end
end
