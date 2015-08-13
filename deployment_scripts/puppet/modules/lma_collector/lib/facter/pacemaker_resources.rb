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

# Return the list of resources managed by Pacemaker
Facter.add('pacemaker_resources') do
    if Facter::Util::Resolution.which('crm_resource')
        setcode do
            # crm_resource -Q -l returns something like this:
            # vip__public
            # p_ntp:0
            # p_ntp:1
            # p_ntp:2
            # p_dns:0
            # ...
            out = Facter::Util::Resolution.exec('crm_resource -Q -l')
            # Facter 1.x support only scalar types so we return the list as a
            # comma-separated string
            out.split(/\n/).collect{ |x| x.gsub(/:.+$/, '')}.uniq().join(',')
        end
    end
end

