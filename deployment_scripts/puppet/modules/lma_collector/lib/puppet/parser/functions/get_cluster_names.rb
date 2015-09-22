# This returns a hash with two keys:
#   'node': list of cluster node name associated to a role
#   'service': list of cluster service name associated to a role
#
# ARG0: The hash table with all informations
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
    roles = args[1]
    cluster_names = { "node" => [].to_set, "service" => [].to_set}

    roles.each do |role|
      # We start by looking into the list of node_cluster_roles
      data['node_cluster_roles'].each do |v|
        # v is a hash like {'controller' => ["primary-controller", "controller"]}
        v.each { |name, t| cluster_names["node"].add(name) if t.include?(role) }
      end

      # Then we are looking into service_cluster_roles
      data['service_cluster_roles'].each do |v|
        v.each { |name, t| cluster_names["service"].add(name) if t.include?(role) }
      end
    end

    return cluster_names
  end
end
