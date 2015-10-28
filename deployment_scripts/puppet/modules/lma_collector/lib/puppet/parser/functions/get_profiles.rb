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

# This returns an array that contains the list of profiles related to a role
# and an empty array if nothing matches.
#
# ARG0: An array of hash table that contains relation between profiles and
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
  newfunction(:get_profiles, :type => :rvalue) do |args|

    data = args[0]
    roles = args[1]

    raise Puppet::ParseError, "data passed to get_profiles is not a list" unless data.is_a?(Array)
    raise Puppet::ParseError, "roles passed to get_profiles is not a list" unless roles.is_a?(Array)

    profiles = [].to_set

    roles.each do |role|
      data.each do |v|
        v.each { |name, t|
            profiles.add(name) if t.include?(role)
        }
      end
    end

    return profiles.to_a()
  end
end
