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
require 'yaml'

HIERA_CONFIG = '/etc/hiera.yaml'

Puppet::Type.type(:hiera_custom_source).provide(:ruby) do
    desc "Support for Hiera source configuration"

    defaultfor :kernel => 'Linux'

    def sources
        if @hiera.has_key?(:hierarchy)
            return @hiera[:hierarchy]
        elsif @hiera.has_key?('hierarchy')
            return @hiera['hierarchy']
        else
            raise Puppet::Error, "No 'hierarchy' key in the Hiera configuration"
        end
    end

    # Load the Hiera configuration
    def load_hiera
        @hiera = YAML.load_file(HIERA_CONFIG)
    end

    # Save the current Hiera configuration
    def save_hiera
        File.open(HIERA_CONFIG, 'w') do |file|
            file.puts @hiera.to_yaml
        end
    end

    def create
        self.load_hiera
        self.sources.insert(0, resource[:name])
        self.save_hiera
    end

    def destroy
        self.load_hiera
        self.sources.select!{|x| x != resource[:name] }
        self.save_hiera
    end

    def exists?
        self.load_hiera
        return self.sources.any?{|x| x == resource[:name] }
    end
end
