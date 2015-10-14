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

# Ex:
#     ARG0: ['controller']
#     ARG1:
#      [{"controller"=>
#         [{"system"=>["cpu-critical-controller", "cpu-warning-controller"]},
#          {"fs"=>["fs-critical", "fs-warning"]}]},
#       ... ]
#
#
#     Results -> ['controller.system', 'controller.fs']
#

module Puppet::Parser::Functions
  newfunction(:get_afd_for_cluster, :type => :rvalue) do |args|

    clusters = args[0]
    afds = args[1]

    raise Puppet::ParseError, "clusters passed to get_afd_for_cluster is not a list" unless clusters.is_a?(Array)
    raise Puppet::ParseError, "afds passed to get_afd_for_cluster is not a list" unless afds.is_a?(Array)

    all = [].to_set()
    clusters.each do |cluster|
        afds.select {|a| a.has_key?(cluster)}.each{|c| c[cluster].each{|i| i.keys().each{|source| all.add("#{cluster}.#{source}")}}}
    end
    return all.to_a()
  end
end
