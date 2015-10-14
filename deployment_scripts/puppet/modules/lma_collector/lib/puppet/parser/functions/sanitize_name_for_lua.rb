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

# This replace hypens by underscores
#
# ARG0: one-two-three
# Results: one_two_three

module Puppet::Parser::Functions
  newfunction(:sanitize_name_for_lua, :type => :rvalue) do |args|
    raise(Puppet::ParseError, "sanitize_name_for_lua: Wrong number of arguments. " +
          "Only one string is needed") if args.size != 1
    return args[0].gsub('-','_')
  end
end
