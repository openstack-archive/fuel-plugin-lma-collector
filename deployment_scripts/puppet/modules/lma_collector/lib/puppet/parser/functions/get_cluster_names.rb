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

# This returns a hash with two keys:
#   'node': list of cluster node name associated to a role
#   'service': list of cluster service name associated to a role
#
# ARG0: The hash table with all information
# ARG1: The role
#
# Ex:
#
# ARG0:
#   node_cluster_roles:
#     - controller: ['primary-controller']
#   service_cluster_roles:
#     - rabbitmq: ['primary-controller']
#
# ARG1: ['primary-controller']
#
# Results -> {'node' => ['controller'],
#             'service' => ['rabbitmq']}
#

module Puppet::Parser::Functions
  newfunction(:get_cluster_names, :type => :rvalue) do |args|

    data = args[0]
    node_key    = 'node_cluster_roles'
    service_key = 'service_cluster_roles'

    raise Puppet::ParseError, "data passed to get_cluster_names is not a hash" unless data.is_a?(Hash)
    raise Puppet::ParseError, "${node_key} definition not found in alarms definitions" unless data.has_key?(node_key)
    raise Puppet::ParseError, "${service_key} definition not found in alarms defintions" unless data.has_key?(service_key)

    roles = args[1]
    raise Puppet::ParseError, "roles passed to get_cluster_names is not a list" unless roles.is_a?(Array)

    cluster_names = { "node" => [].to_set, "service" => [].to_set}

    roles.each do |role|
      # We start by looking into the list of node_cluster_roles
      data[node_key].each do |v|
        # v is a hash like {'controller' => ["primary-controller", "controller"]}
        v.each { |name, t| cluster_names["node"].add(name) if t.include?(role) }
      end

      # if cluster_names["node"] is empty, it means that we didn't find a cluster
      # name that matches with role. So add "default" name.
      cluster_names["node"].add("default") if cluster_names["node"].empty?

      # Then we are looking into service_cluster_roles
      data[service_key].each do |v|
        v.each { |name, t| cluster_names["service"].add(name) if t.include?(role) }
      end

    end

    return cluster_names
  end
end
