#    Copyright 2016 Mirantis, Inc.
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

# This function is used by the lma_collector::collectd::python defined
# type to work-around a bug in collectd::plugin::python::module where
# the config hash cannot include values that are arrays or hashes.
# See https://github.com/voxpupuli/puppet-collectd/issues/390.
#
# Ex:
#
# ARG0:
#    {"key1" => ["e1", "e2"],
#     "key2" => {"k1" => "v1", "k2" => "v2"}
#     "key3" => "val3"}
#
# Result:
#     {"key1 e1" => "", "key1 e2" => "",
#      "key2 k1" => "v1", "key2 k2" => "v1",
#      "key3" => "val3"}
#

module Puppet::Parser::Functions
  newfunction(:adapt_collectd_python_plugin_config, :type => :rvalue) do |args|

    config = args[0]
    raise Puppet::ParseError, "arg[0] isn't a hash" unless config.is_a?(Hash)

    adapted_config = Hash.new

    config.each do |key,val|
        if val.is_a?(Array)
            val.each do |elt|
              adapted_config["#{key} #{elt}"] = ""
            end
        elsif val.is_a?(Hash)
            val.each do |k,v|
              adapted_config["#{key} #{k}"] = "#{v}"
            end
        else
            adapted_config["#{key}"] = "#{val}"
        end
    end

    return adapted_config

  end
end
