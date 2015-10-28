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

# This returns an array that contains the list of services or nodes related
# to a role.
#
# ARG0: An array of hash table that contains relation between node/service and
#       roles.
# ARG1: An array of roles
#
# Ex:
#
#     ARG0:
#       [{"controller"=>["primary-controller", "controller"]},
#        {"compute"=>["compute"]},
#        {"storage"=>["cinder", "ceph-osd"]},
#        {"influxdb"=>["influxdb-grafana"]}]
#
#     ARG1: ['primary-controller']
#
#     Results -> ['controller']
#

module Puppet::Parser::Functions
  newfunction(:get_cluster_names, :type => :rvalue) do |args|

    data = args[0]
    roles = args[1]
    has_default = args[2] or false

    raise Puppet::ParseError, "data passed to get_cluster_names is not a list" unless data.is_a?(Array)
    raise Puppet::ParseError, "roles passed to get_cluster_names is not a list" unless roles.is_a?(Array)

    cluster_names = [].to_set

    roles.each do |role|
      data.each do |v|
        v.each { |name, t|
            cluster_names.add(name) if t.include?(role)
        }
      end

      # if cluster_names["node"] is empty, it means that we didn't find a cluster
      # name that matches with role. So add "default" name if there is a default
      # value
      cluster_names.add("default") if cluster_names.empty? and has_default
    end

    return cluster_names.to_a()
  end
end
