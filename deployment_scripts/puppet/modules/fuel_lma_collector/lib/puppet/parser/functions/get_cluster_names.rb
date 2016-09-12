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
# Returns an array containing the AFD profiles associated to a MOS role.
#
# ARG0: Hash of arrays that contains relation between AFD profile and node's roles.
# ARG1: Array of node's roles
#
# Ex:
#
#     ARG0:
#        {"controller"=>["primary-controller", "controller"],
#         "compute"=>["compute"],
#         "storage"=>["cinder", "ceph-osd"],
#         "influxdb"=>["influxdb-grafana"]}
#
#     ARG1: ['primary-controller']
#
#     Results -> ['controller']
#

module Puppet::Parser::Functions
  newfunction(:get_cluster_names, :type => :rvalue) do |args|

    data = args[0]
    roles = args[1]

    raise Puppet::ParseError, "arg[0] isn't a hash" unless data.is_a?(Hash)
    raise Puppet::ParseError, "arg[1] isn't an array" unless roles.is_a?(Array)

    cluster_names = Set.new([])

    roles.each do |role|
        data.each do |k,v|
            cluster_names << k if v['roles'].include?(role)
        end
    end

    return cluster_names.to_a()
  end
end
